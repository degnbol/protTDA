// Error: "Unable to get a routing table for database 'neo4j' because this database is unavailable"
// Explanation: seems there was multiple things running.
// Help from seeing messages from neo4j console.
// Solution: Uninstalled everything
// Restart. Make sure no neo4j process is still somehow running:
ps aux | grep neo4j
kill <PID>
// Reinstall neo4j and follow ./install.sh
// I also did (before actually calling kill, these sentences are not in the 
// order they were actually done):
show databases
// shows a statusMessage for neo4j where there should be an empty string.
drop neo4j
// doesn't seem to delete any files in neo4j/data/databases/neo4j
create neo4j
start neo4j
:use neo4j
// at this point it worked. It might have been a disk full issue since I think 
// I did this same stuff before without success.
// I then realized this worked because I had changed the folder from PH/data/ 
// to PH/neo4j/data and there was stuff being created in PH/data/ since the 
// conf file still referenced that location by mistake.

