require('dotenv').config();
const jwt=require('jsonwebtoken');
const express=require('express');
const bcrypt=require('bcrypt');
const db=require('./database.js');
const app=express();
app.use(express.json());
app.post('/api/login',async(req,res)=>{

try{const{email,password}=req.body
if(!email||!password){

return res.status(401).json({error:'invalid credentials'});




}
const result=await db.query(
    'SELECT * FROM users  WHERE email=$1',
    [email]
)
if(result.rows.length===0){
return res.status(401).json({error:'invalid  credentials'});


}
const user=result.rows[0]
const compare=await bcrypt.compare(password,user.password_hash);
if(compare===false){
return res.status(401).json({
    error:'wrong password '
});
}
const token=jwt.sign({
userId:user.id,
userEmail:user.email
},


process.env.JWT_SECRET,
{expiresIn:'7d'}

);


return res.status(200).json({

message:"sucessfully logged in ",
token:token,
user:{
username:user.name,
useremail:user.email,
userid:user.id



}


});
}

catch(error){
console.log(error);
res.status(500).json({error:'server error'})



}





})
