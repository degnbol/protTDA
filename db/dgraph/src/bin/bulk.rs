use std::io::prelude::*;
use std::env;
use std::fs::{File, read_dir};
use std::error::Error;
use std::io::BufReader;
use flate2::read::GzDecoder;
use dgraph::{make_dgraph, Dgraph};
use serde::{Deserialize, Serialize};
use serde_json;
use std::path::Path;
use osstrtools::OsStrTools;
use itertools::izip;
use std::collections::HashMap;

#[derive(Serialize, Deserialize, Debug)]
struct UID {
    uid: String
}
impl UID {
    fn new(uid: &str) -> Self {
        UID { uid: uid.to_string() }
    }
}

#[derive(Serialize, Deserialize, Debug)]
struct PH {
    n: i32,
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
impl PH {
    fn explode(self) -> (Vec<Ca>, [Vec<f64>; 2], [Vec<f64>; 2], Vec<Vec<Vec<usize>>>, Vec<Vec<Vec<usize>>>) {
        let mut cas = Vec::with_capacity(self.n as usize);
        for (x, y, z, c1, c2) in izip!(self.x, self.y, self.z, self.cent1, self.cent2) {
            cas.push(Ca::new(x, y, z, c1, c2));
        }
        (cas, self.bars1, self.bars2, self.reps1, self.reps2)
    }
}

#[derive(Serialize, Deserialize, Debug)]
struct Ca {
    #[serde(rename = "dgraph.type")]
    kind: [String; 1],
    x: f64,
    y: f64,
    z: f64,
    cent1: f64,
    cent2: f64,
}
impl Ca {
    fn new(x: f64, y: f64, z: f64, cent1: f64, cent2: f64) -> Self {
        Self { kind: ["Ca".to_string()], x: x, y: y, z: z, cent1: cent1, cent2: cent2 }
    }
}

#[derive(Serialize, Deserialize, Debug)]
struct Simplex1 {
    #[serde(rename = "dgraph.type")]
    kind: [String; 1],
    v1: UID,
    v2: UID,
}
impl Simplex1 {
    fn new(v1: &str, v2: &str) -> Self {
        Self { kind: ["Simplex1".to_string()], v1: UID::new(v1), v2: UID::new(v2) }
    }
}

#[derive(Serialize, Deserialize, Debug)]
struct Simplex2 { 
    #[serde(rename = "dgraph.type")]
    kind: [String; 1],
    v1: UID,
    v2: UID,
    v3: UID,
}
impl Simplex2 {
    fn new(v1: &str, v2: &str, v3: &str) -> Self {
        Self { kind: ["Simplex2".to_string()], v1: UID::new(v1), v2: UID::new(v2), v3: UID::new(v3) }
    }
}

#[derive(Serialize, Deserialize, Debug)]
struct Rep1 {
    #[serde(rename = "dgraph.type")]
    kind: [String; 1],
    birth: f64,
    death: f64,
    persistence: f64,
    simplices: Vec<Simplex1>,
}
impl Rep1 {
    fn new(birth: f64, death: f64, simplices: Vec<Simplex1>) -> Self {
        Self {
            kind: ["Rep1".to_string()], birth: birth, death: death, persistence: death - birth, simplices: simplices
        }
    }
}

#[derive(Serialize, Deserialize, Debug)]
struct Rep2 {
    #[serde(rename = "dgraph.type")]
    kind: [String; 1],
    birth: f64,
    death: f64,
    persistence: f64,
    simplices: Vec<Simplex2>,
}
impl Rep2 {
    fn new(birth: f64, death: f64, simplices: Vec<Simplex2>) -> Self {
        Self {
            kind: ["Rep2".to_string()], birth: birth, death: death, persistence: death - birth, simplices: simplices
        }
    }
}

#[derive(Serialize, Deserialize, Debug)]
struct AFProt {
    #[serde(rename = "dgraph.type")]
    kind: [String; 1],
    acc: String,
    cas: Vec<UID>,
    reps1: Vec<Rep1>,
    reps2: Vec<Rep2>,
}
impl AFProt {
    fn new(acc: &str, cas: Vec<UID>, reps1: Vec<Rep1>, reps2: Vec<Rep2>) -> Self {
        Self { kind: ["AFProt".to_string()], acc: acc.to_string(), cas: cas, reps1: reps1, reps2: reps2 }
    }
    fn from(acc: &str, cas_UIDs: Vec<&String>, bars1: [Vec<f64>; 2], bars2: [Vec<f64>; 2], raw_reps1: Vec<Vec<Vec<usize>>>, raw_reps2: Vec<Vec<Vec<usize>>>) -> AFProt {
        let mut reps1 = Vec::with_capacity(raw_reps1.len());
        let [births, deaths] = bars1;
        for (birth, death, rep) in izip!(births, deaths, raw_reps1) {
            let mut simplices = Vec::with_capacity(rep.len());
            for simplex in rep {
                // -1 for converting from one- to zero-indexing.
                simplices.push(Simplex1::new(cas_UIDs[simplex[0]-1], cas_UIDs[simplex[1]-1]));
            }
            reps1.push(Rep1::new(birth, death, simplices));
        }
        let mut reps2 = Vec::with_capacity(raw_reps2.len());
        let [births, deaths] = bars2;
        for (birth, death, rep) in izip!(births, deaths, raw_reps2) {
            let mut simplices = Vec::with_capacity(rep.len());
            for simplex in rep {
                // -1 for converting from one- to zero-indexing.
                simplices.push(Simplex2::new(cas_UIDs[simplex[0]-1], cas_UIDs[simplex[1]-1], cas_UIDs[simplex[2]-1]));
            }
            reps2.push(Rep2::new(birth, death, simplices));
        }
        let mut cas = Vec::with_capacity(cas_UIDs.len());
        for uid in cas_UIDs { cas.push(UID::new(uid)); }
        AFProt::new(acc, cas, reps1, reps2)
    }
}


#[derive(Serialize, Deserialize, Debug)]
struct Root {
    me: Vec<AFProt>,
}

// https://docs.rs/serde_json/1.0.93/serde_json/de/fn.from_reader.html
fn readph<P: AsRef<Path>>(path: P) -> Result<PH, Box<dyn Error>> {
    let file = File::open(path)?;
    let reader = BufReader::new(file);
    let d = GzDecoder::new(reader);
    let ph: PH = serde_json::from_reader(d)?;
    Ok(ph)
}


fn main() {
    // https://crates.io/crates/dgraph#create-a-client
    let dgraph = make_dgraph!(dgraph::new_dgraph_client("localhost:9080"));
    
    // let args: Vec<String> = env::args().skip(1).collect();
    // println!("{:?}", args);
    let dir = env::args().nth(1).expect("Path arg missing.");
    let paths = read_dir(dir).unwrap().take(100);
    // let path = "/home/opc/protTDA/data/alphafold/PH/100/100-0/AF-A0A3S0EAG4-F1-model_v3.json.gz".to_string();
    
    let mut txn = dgraph.new_txn();
    
    for path in paths {
        println!("{:?}", path);
    
        let path = path.unwrap().path();
        let fname = Path::file_name(&path).unwrap();
        
        if fname.to_str().unwrap().starts_with("AF") {

            let acc = fname.split("-")[1];
            let ph = readph(&path).unwrap();

            let (cas, bars1, bars2, reps1, reps2) = ph.explode();


            let mut mutation = dgraph::Mutation::new();
            mutation.set_set_json(serde_json::to_vec(&cas).expect("Failed to serialize JSON."));
            let assigned = txn.mutate(mutation).expect("Failed to create data.");
            println!("Number of created carbon alpha nodes:");
            println!("{}", assigned.uids.len());

            let prot = AFProt::from(acc.to_str().unwrap(), assigned.uids.values().collect(), bars1, bars2, reps1, reps2);

            let mut mutation = dgraph::Mutation::new();
            mutation.set_set_json(serde_json::to_vec(&prot).expect("Failed to serialize JSON."));
            let assigned = txn.mutate(mutation).expect("Failed to create data.");
            println!("Number of created nodes:");
            println!("{}", assigned.uids.len());

        }
    }
    
    txn.commit().expect("Failed to commit mutation");
    
}


