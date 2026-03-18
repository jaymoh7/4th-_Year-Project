require('dotenv').config();
const db=require('./database.js');
const disease=require('./server.js');
app.get('/api/diseases',async(req,res)=>{
try{
const result=await db.query(
'SELECT * FROM diseases WHERE id=$1',
[disease]
);
if(result.rows.length===0){
return res.status(401).json({
error:'there is no such kind of a disease yet'

});
const disease=result.rows[0];



}








}
catch(error){
console.log(error);
return res.status(500).json({
    error:'bad request'
})


}




})