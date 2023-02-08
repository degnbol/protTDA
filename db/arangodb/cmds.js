
db._createDatabase("protTDA");
db._useDatabase("protTDA");

db._create('AF');
db._collections();
db.AF;

// _key is indexed identifier
db.AF.save({ _key: "ACCESSION",  n : 123, x : [1.5, 2.1, 3.] });
db._update("AF/ACCESSION", {cent1 : [0.001, 0.01, 0.1] });

db.AF.document("ACCESSION");
db._document("AF/ACCESSION");

db.AF.toArray();
db.AF.count();


db.AF.byExample({n : 123}).toArray();

db._query(`
    FOR prot IN AF
      FILTER prot.n > 100 && prot.x ANY >= 2.4
      RETURN { acc: prot._key }
  `).toArray();


db._remove("AF/ACCESSION");
db.AF.remove("ACCESSION");
db._drop('AF');
db._useDatabase("_system");
db._dropDatabase("protTDA");

