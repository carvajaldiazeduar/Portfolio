
const categorySel=document.getElementById('category');
const fromSel=document.getElementById('fromUnit');
const toSel=document.getElementById('toUnit');
const valueInput=document.getElementById('value');
const resultDiv=document.getElementById('result');
const form=document.getElementById('convertForm');

fetch('/api/categories')
.then(r=>r.json())
.then(data=>{
for(const cat in data){
const opt=document.createElement('option');
opt.value=cat;
opt.textContent=cat.charAt(0).toUpperCase()+cat.slice(1);
categorySel.appendChild(opt);
}
window.categories=data;
});

categorySel.addEventListener('change',()=>{
const cat=categorySel.value;
const units=window.categories[cat]||[];
fromSel.innerHTML='';
toSel.innerHTML='';
units.forEach(u=>{
fromSel.appendChild(new Option(u,u));
toSel.appendChild(new Option(u,u));
});
});

form.addEventListener('submit',e=>{
e.preventDefault();
const value=parseFloat(valueInput.value);
const from=fromSel.value;
const to=toSel.value;
if(isNaN(value)||!from||!to){
resultDiv.textContent='Please fill all fields';
resultDiv.className='error';
return;
}
fetch('/api/convert',{
method:'POST',
headers:{'Content-Type':'application/json'},
body:JSON.stringify({value,from,to})
})
.then(r=>r.json())
.then(data=>{
if(data.error){
resultDiv.textContent='Error: '+data.error;
resultDiv.className='error';
}else{
resultDiv.textContent=`${data.value} ${data.from} = ${data.result} ${data.to}`;
resultDiv.className='';
}
});
});

