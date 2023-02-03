#!/usr/bin/env julia
using Mongoc; mg = Mongoc
using Mongoc: BSON
B = BSON
D = Dict

# assuming server is running with a protTDA database with a collection AF 
# defined.
client = mg.Client()
db = client["protTDA"]
af = db["AF"]

# meta-programming.
# Define String accepting versions and set AF as default collection.
for fun in (
            :find,
            :find_one,
            :find_one_and_delete,
            :find_one_and_replace,
            :find_one_and_update,
           )
    eval(quote
             function mg.$fun(coll::mg.Collection, query::String; options...)
                 mg.$fun(coll, BSON(query); options...)
             end
         end)
    
    eval(quote
             function mg.$fun(coll::mg.Collection, query::Pair...; options...)
                 mg.$fun(coll, BSON(query...); options...)
             end
         end)
    
    eval(quote
             function mg.$fun(coll::mg.Collection, query::Pair...; projection::Dict)
                 mg.$fun(coll, BSON(query...); options=B("projection"=>projection))
             end
         end)
    
    
    eval(quote
             function mg.$fun(query::Pair...; options...)
                 mg.$fun(af, BSON(query...); options...)
             end
         end)
    
    eval(quote
             function mg.$fun(query::Pair...; projection::Dict)
                 mg.$fun(af, BSON(query...); options=B("projection"=>projection))
             end
         end)
end



