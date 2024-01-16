use std::io::prelude::*;
use std::env;
use std::fs::{read_dir, read};
use std::error::Error;
use std::io::BufReader;
use flate2::read::GzDecoder;
use zune_inflate::DeflateDecoder;
use serde::{Deserialize, Serialize};
use serde_json;
use std::path::Path;
use osstrtools::OsStrTools;
use itertools::izip;
use hdf5;
use ndarray::{arr2, s};

#[derive(Serialize, Deserialize, Debug)]
struct PH {
    n: u32,
    x: Vec<f64>,
    y: Vec<f64>,
    z: Vec<f64>,
    cent1: Vec<f64>,
    cent2: Vec<f64>,
    bars1: [Vec<f64>; 2],
    bars2: [Vec<f64>; 2],
    reps1: Vec<Vec<Vec<usize>>>,
    reps2: Vec<Vec<Vec<usize>>>,
}

// https://docs.rs/serde_json/1.0.93/serde_json/de/fn.from_reader.html
fn readph<P: AsRef<Path>>(path: P) -> Result<PH, Box<dyn Error>> {
    let compressed = read(path)?;
    let mut decoder = DeflateDecoder::new(&compressed);
    let decompressed = decoder.decode_gzip().unwrap();
    let ph: PH = serde_json::from_slice(&decompressed)?;
    Ok(ph)
}

fn main() {
    // let args: Vec<String> = env::args().skip(1).collect();
    // println!("{:?}", args);
    let dir = env::args().nth(1).expect("Path arg missing.");
    let paths = read_dir(dir).unwrap().take(1000);
    // let path = "/home/opc/protTDA/data/alphafold/PH/100/100-0/AF-A0A3S0EAG4-F1-model_v3.json.gz".to_string();
    
    // open for writing
    let file = hdf5::File::create("lars.h5").unwrap();
    
    for path in paths {
        // println!("{:?}", path);
    
        let path = path.unwrap().path();
        let fname = Path::file_name(&path).unwrap();
        
        if fname.to_str().unwrap().starts_with("AF") {

            let acc = fname.split("-")[1];
            let ph = readph(&path).unwrap();

            // create a group 
            let group = file.create_group(acc.to_str().unwrap()).unwrap();
            // create an attr with fixed shape but don't write the data
            // let n = group.new_attr::<u32>().create("n").unwrap();
            // let n = group.new_attr_builder().with_data(ph.n);
            // // write the attr data
            // n.write(ph.n);

            let AA = dataset.new_attr::<hdf5::types::VarLenAscii>().create("AA")?;
            let value: hdf5::types::VarLenAscii = "AAGGVVVVVCC".parse().unwrap();
            attr.write_scalar(&value)?;


        }
    }
    
    // write("bulk.json", serde_json::to_string(&prots).unwrap());
    
}

