use std::io::prelude::*;
use std::env;
use std::fs::File;
use std::error::Error;
use std::io::BufReader;
use flate2::read::GzDecoder;
use dgraph::{make_dgraph, Dgraph};
use serde::{Deserialize, Serialize};
use serde_json;
use std::path::Path;
use osstrtools::OsStrTools;
use itertools::izip;

#[derive(Serialize, Deserialize, Debug)]
struct PH {
    n: i32,
    x: Vec<f32>,
    y: Vec<f32>,
    z: Vec<f32>,
    cent1: Vec<f32>,
    cent2: Vec<f32>,
    bars1: Vec<Vec<f32>>,
    bars2: Vec<Vec<f32>>,
    reps1: Vec<Vec<Vec<usize>>>,
    reps2: Vec<Vec<Vec<usize>>>,
}

#[derive(Serialize, Deserialize, Debug)]
struct Ca {
    xyz: [f32; 3],
    cent1: f32,
    cent2: f32,
}

#[derive(Serialize, Debug)]
struct Simplex1<'a> {
    verts: [&'a Ca; 2],
}

#[derive(Serialize, Debug)]
struct Simplex2<'a> {
    verts: [&'a Ca; 3],
}

#[derive(Serialize, Debug)]
struct Rep1<'a> {
    birth: f32,
    death: f32,
    persistence: f32,
    simplices: Vec<Simplex1<'a>>,
}

#[derive(Serialize, Debug)]
struct Rep2<'a> {
    birth: f32,
    death: f32,
    persistence: f32,
    simplices: Vec<Simplex2<'a>>,
}

#[derive(Serialize, Debug)]
struct AFProt<'a> {
    acc: String,
    xyz: Vec<Ca>,
    reps1: Vec<Rep1<'a>>,
    reps2: Vec<Rep2<'a>>,
}

fn drop_schema(dgraph: &Dgraph) {
    let op_drop = dgraph::Operation {
        drop_all: true,
        ..Default::default()
    };

    dgraph.alter(&op_drop).expect("Failed to drop schema.");

    println!("Dropped the schema.");
}

fn set_schema(dgraph: &Dgraph) {
    let op_schema = dgraph::Operation {
        schema: r#"
            acc: string @index(exact) .
        "#
        .to_string(),
        ..Default::default()
    };

    dgraph.alter(&op_schema).expect("Failed to set schema.");

    println!("Altered schema.");
}

// https://docs.rs/serde_json/1.0.93/serde_json/de/fn.from_reader.html
fn readph<P: AsRef<Path>>(path: P) -> Result<PH, Box<dyn Error>> {
    let file = File::open(path)?;
    let reader = BufReader::new(file);
    let d = GzDecoder::new(reader);
    let ph: PH = serde_json::from_reader(d)?;
    Ok(ph)
}

fn ph2prot(ph: &PH, acc: &str) {
    let mut cas = Vec::with_capacity(ph.n as usize);
    for (x, y, z, c1, c2) in izip!(&ph.x, &ph.y, &ph.z, &ph.cent1, &ph.cent2) {
        cas.push(Ca { xyz: [*x, *y, *z], cent1: *c1, cent2: *c2 });
    }
    let mut reps1 = Vec::with_capacity(ph.reps1.len());
    for (birth, death, rep) in izip!(&ph.bars1[0], &ph.bars1[1], &ph.reps1) {
        let mut simplices = Vec::with_capacity(rep.len());
        for simplex in rep {
            simplices.push(Simplex1 { verts: [&cas[simplex[0]], &cas[simplex[1]]]});
        }
        reps1.push(Rep1 { birth: *birth, death: *death, persistence: *death - *birth, simplices: simplices });
    }
    let mut reps2 = Vec::with_capacity(ph.reps2.len());
    for (birth, death, rep) in izip!(&ph.bars2[0], &ph.bars2[1], &ph.reps2) {
        let mut simplices = Vec::with_capacity(rep.len());
        for simplex in rep {
            simplices.push(Simplex2 { verts: [&cas[simplex[0]], &cas[simplex[1]], &cas[simplex[2]]]});
        }
        reps2.push(Rep2 { birth: *birth, death: *death, persistence: *death - *birth, simplices: simplices });
    }
    AFProt {
        acc: acc.to_string(),
        xyz: Vec::new(),
        reps1: reps1,
        reps2: reps2,
    };
}


fn main() {
    // https://crates.io/crates/dgraph#create-a-client
    let dgraph = make_dgraph!(dgraph::new_dgraph_client("localhost:9080"));
    
    let args: Vec<String> = env::args().skip(1).collect();
    // Or:
    // let path = env::args().nth(1).expect("Path arg missing.");
    println!("{:?}", args);
    
    let path = Path::new("/home/opc/protTDA/data/alphafold/PH/100/100-0/AF-A0A3S0EAG4-F1-model_v3.json.gz");
    let acc = Path::file_name(path).unwrap().split("-")[1];
    let ph = readph(path).unwrap();
    
    let prot = ph2prot(&ph, acc.to_str().unwrap());
    
    // drop_schema(&dgraph);
    // set_schema(&dgraph);
    
    let mut txn = dgraph.new_txn();
    
    let mut mutation = dgraph::Mutation::new();
    mutation.set_set_json(serde_json::to_vec(&prot).expect("Failed to serialize JSON."));
    let assigned = txn.mutate(mutation).expect("Failed to create data.");

}


