#!/usr/bin/env python3
# Run pymol super.
# Write to first arg as compressed TSV.
# Write output of pymol super command to first positional arg.
# Any extra positional args will be the "i" or "from" entries. Default is all vs all.
# https://pymolwiki.org/index.php/Super
# output format: (https://pymolwiki.org/index.php/Align)
# 1. RMSD after refinement
# 2. Number of aligned atoms after refinement
# 3. Number of refinement cycles
# 4. RMSD before refinement
# 5. Number of aligned atoms before refinement
# 6. Raw alignment score
# 7. Number of residues aligned
import sys
import pandas as pd
# from pandas_multiprocess import multi_process
# https://github.com/xieqihui/pandas-multiprocess/blob/master/pandas_multiprocess/multiprocess.py
import multiprocessing
import time
import os
import pandas as pd
from tqdm import tqdm
import logging
logger = logging.getLogger(__name__)


class Consumer(multiprocessing.Process):
    ''' Objects with this type work as processers in the multiprocessing job.
    '''
    def __init__(self, func, task_queue, result_queue, error_queue,
                 **args):
        '''Constructs a `Consumer` instance
        Args:
            func (function): the function to apply on each row of the input
                Dataframe
            task_queue (multiprocessing.JoinableQueue): A queue of the
                input data.
            result_queue (multiprocessing.Queue): A queue to collect
                the output of func.
            error_queue (multiprocessing.Queue): A queue to collect
                exception information of child processes.
            args (dict): A dictionary of arguments to be passed to func.
        '''
        multiprocessing.Process.__init__(self)
        self._func = func
        self._task_queue = task_queue
        self._result_queue = result_queue
        self._error_queue = error_queue
        self._args = args

    def run(self):
        '''Define the job of each process to run.
        '''
        while True:
            next_task = self._task_queue.get()
            # If there is any error, only consume data but not run the job
            if self._error_queue.qsize() > 0:
                self._task_queue.task_done()
                continue
            if next_task is None:
                # Poison pill means shutdown
                self._task_queue.task_done()
                break
            try:
                answer = self._func(next_task, **self._args)
                self._task_queue.task_done()
                self._result_queue.put(answer)
            except Exception as e:
                self._task_queue.task_done()
                self._error_queue.put((os.getpid(), e))
                logger.error(e)
                continue


class TaskTracker(multiprocessing.Process):
    '''An object to track the progress of the multiprocessing job.
    An object of this type will keep checking the amount of data remains in the
    task queue and output the percentage of finished task.
    Attributes:
        total_task (int): Total number of tasks in the task queue at the
            begining.
        current_state (int): Current finished percentage of total tasks.
    '''
    def __init__(self, task_queue, verbose=True):
        '''Construct an instance of TaskTracker
        Args:
            task_queue (multiprocessing.JoinableQueue): A queue of the
                input data.
            verbose (bool, optional): Set to False to disable verbose output.
        '''
        multiprocessing.Process.__init__(self)
        self._task_queue = task_queue
        self.total_task = self._task_queue.qsize()
        self.current_state = None
        self.verbose = verbose

    def run(self):
        '''Define the job of each process to run.
        '''
        if self.verbose:
            pbar = tqdm(total=100)
        while True:
            task_remain = self._task_queue.qsize()
            task_finished = int((float(self.total_task - task_remain) /
                                 float(self.total_task)) * 100)
            if task_finished != self.current_state:
                self.current_state = task_finished
                logger.info('{0}% done'.format(task_finished))
                if self.verbose and task_finished > 0:
                    pbar.update(1)
            if task_remain == 0:
                break
        logger.debug('All task data cleared')

        
def multi_process(func, data, num_process=None, verbose=True, **args):
    '''Function to use multiprocessing to process pandas Dataframe.
    This function applies a function on each row of the input DataFrame by
    multiprocessing.
    Args:
        func (function): The function to apply on each row of the input
            Dataframe. The func must accept pandas.Series as the first
            positional argument and return a pandas.Series.
        data (pandas.DataFrame): A DataFrame to be processed.
        num_process (int, optional): The number of processes to run in
            parallel. Defaults to be the number of CPUs of the computer.
        verbose (bool, optional): Set to False to disable verbose output.
        args (dict): Keyword arguments to pass as keywords arguments to `func`
    return:
        A dataframe containing the results
    '''
    # Check arguments value
    assert isinstance(data, pd.DataFrame), \
        'Input data must be a pandas.DataFrame instance'
    if num_process is None:
        num_process = multiprocessing.cpu_count()
    # Establish communication queues
    tasks = multiprocessing.JoinableQueue()
    results = multiprocessing.Queue()
    error_queue = multiprocessing.Queue()
    start_time = time.time()
    # Enqueue tasks
    num_task = len(data)
    for i in range(num_task):
        tasks.put(data.iloc[i, :])
    # Add a poison pill for each consumer
    for i in range(num_process):
        tasks.put(None)

    logger.info('Create {} processes'.format(num_process))
    consumers = [Consumer(func, tasks, results, error_queue, **args)
                 for i in range(num_process)]
    for w in consumers:
        w.start()
    # Add a task tracking process
    task_tracker = TaskTracker(tasks, verbose)
    task_tracker.start()
    # Wait for all input data to be processed
    tasks.join()
    # If there is any error in any process, output the error messages
    num_error = error_queue.qsize()
    if num_error > 0:
        for i in range(num_error):
            logger.error(error_queue.get())
        raise RuntimeError('Multi process jobs failed')
    else:
        # Collect results
        result_table = []
        while num_task:
            result = results.get()
            if isinstance(result, list):
                result_table.extend(result)
            else:
                result_table.append(result)
            num_task -= 1
        df_results = pd.DataFrame(result_table)
        logger.info("Jobs finished in {0:.2f}s".format(
            time.time()-start_time))
        return df_results


outfile = sys.argv[1]

names = cmd.get_names()
n = len(names)
sys.stderr.write(f"{n} names\n")

nis = []
njs = []

if len(sys.argv) > 2:
    names_i = sys.argv[2:]
    assert all([n in names for n in names_i]), "Not all provided names found among loaded structures"
    # all v all for the provided names
    for i, ni in enumerate(names_i):
        for j in range(i+1, len(names_i)):
            nis.append(ni)
            njs.append(names[j])
    # all of provided names vs all of the remaining names
    for ni in names_i:
        for nj in set(names) - set(names_i):
            nis.append(ni)
            njs.append(nj)
else:
    for i, ni in enumerate(names):
        for j in range(i+1, n):
            nis.append(ni)
            njs.append(names[j])



df = pd.DataFrame(dict(i=nis, j=njs))
outcols = ['RMSD_post', 'atoms_post', 'cycles', 'RMSD_pre', 'atoms_pre', 'raw', 'res_aligned']
df[outcols] = 0

if len(sys.argv) == 1:
    assert len(df) == (n ** 2 - n) / 2
sys.stderr.write(f"{len(df)} comparisons\n")

def row_super(row):
    # data_row (pd.Series): a row of a panda Dataframe
    # args: a dict of additional arguments
    row[outcols] = cmd.super(row.i, row.j, cycles=0)
    return row

df_res = multi_process(func=row_super, data=df)

sanity = len(df) == (n ** 2 - n) / 2
sys.stderr.write(f"{sanity}\n")

# compression is inferred from filename
df_res.to_csv(outfile, sep='\t', index=False)

