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
use std::collections::HashMap;

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
            x: float .
            y: float .
            z: float .
            cent1: float .
            cent2: float .
            type Ca {
                x: Float!
                y: Float!
                z: Float!
                cent1: Float!
                cent2: Float!
            }
            v1: uid .
            v2: uid .
            v3: uid .
            type Simplex1 {
                v1: Ca!
                v2: Ca!
            }
            type Simplex2 {
                v1: Ca!
                v2: Ca!
                v3: Ca!
            }
            birth: float .
            death: float .
            persistence: float @index(float) .
            simplices: [uid] @count .
            type Rep1 {
                birth: Float!
                death: Float!
                persistence: Float!
                simplices: [Simplex1!]!
            }
            type Rep2 {
                birth: Float!
                death: Float!
                persistence: Float!
                simplices: [Simplex2!]!
            }
            acc: string @index(exact) .
            n: int @index(int) .
            cas: [uid] @count .
            reps1: [uid] @count .
            reps2: [uid] @count .
            type AFProt {
                acc: String!
                n: Int!
                cas: [Ca!]!
                reps1: [Rep1!]!
                reps2: [Rep2!]!
            }
        "#
        .to_string(),
        ..Default::default()
    };

    dgraph.alter(&op_schema).expect("Failed to set schema.");
    println!("Altered schema.");
}

fn main() {
    // https://crates.io/crates/dgraph#create-a-client
    let dgraph = make_dgraph!(dgraph::new_dgraph_client("localhost:9080"));
    
    drop_schema(&dgraph);
    set_schema(&dgraph);
    
}


