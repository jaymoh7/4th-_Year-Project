require('dotenv').config();
const {Pool}=require('pg');
const pool=new Pool({

user:process.env.DB_USER||'postgres',
host:process.env.DB_HOST||'localhost',
database:process.env.DB_NAME||'plant_diseases_app',
password:process.env.DB_PASSWORD||'Wainaina6371.',
port:process.env.DB_PORT||'5432'




});
pool.connect((err,client,release)=>{
    if(err){
        console.error(err.message);
    }
    else{
        console.log("server is connected successfully");
        release();
    }




});
module.exports=pool
