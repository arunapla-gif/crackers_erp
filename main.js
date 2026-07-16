
function toggleCompactMenu(){
  const menu=document.getElementById("compactMenu");
  if(menu) menu.classList.toggle("show");
}
function closeCompactMenu(){
  const menu=document.getElementById("compactMenu");
  if(menu) menu.classList.remove("show");
}
function compactSwitch(pageId,type){
  document.querySelectorAll(".page").forEach(p=>p.classList.remove("active"));
  document.getElementById(pageId).classList.add("active");
  if(type==="MASTER"){
    setTheme("MASTER");
    document.getElementById("docBadge").innerText =
      pageId === "productMasterPage" ? "PRODUCT MASTER" :
      pageId === "godownMasterPage" ? "GODOWN MASTER" :
      pageId === "vehicleMasterPage" ? "VEHICLE MASTER" :
      pageId === "purchaseEntryPage" ? "PURCHASE ENTRY" :
      pageId === "stockTransferPage" ? "STOCK TRANSFER" :
      pageId === "godownStockPage" ? "GODOWN STOCK" :
      pageId === "reportsPage" ? "REPORTS" : "CUSTOMER MASTER";
    closeCompactMenu();
    return;
  }
  currentType=type;
  setTheme(type);
  updateInvoiceNumber();
  refreshActiveProductDatalist();
  resetRows(); setTimeout(()=>{ if(document.getElementById('rows') && document.getElementById('rows').children.length===0){ addRow(); } },100);
  closeCompactMenu();
}
document.addEventListener("keydown",function(e){
  if(e.key==="Escape"){closeCompactMenu();}
});


function showToast(message){
  const t=document.getElementById("toastNote");
  if(!t) return;
  t.innerText=message;
  t.classList.add("show");
  clearTimeout(window.__toastTimer);
  window.__toastTimer=setTimeout(()=>t.classList.remove("show"),1600);
}





const ERPStorage = (() => {
  const KEY = "crackers_erp_local_db_v2";

  function setStatus(text){
    const el = document.getElementById("storageStatus");
    if(el) el.innerText = text;
  }

  function snapshot(){
    return {currentType,counters,invoiceRecords,customers,invoiceProducts,estimateProducts,godowns,purchases,stockLedger,vehicles,transfers,purchaseCounter,transferCounter,savedAt:new Date().toISOString()};
  }

  function apply(data){
    if(!data) return;
    if(data.currentType) currentType = data.currentType;
    if(data.counters) Object.assign(counters, data.counters);
    if(Array.isArray(data.invoiceRecords)) invoiceRecords = data.invoiceRecords;
    if(Array.isArray(data.customers)) customers = data.customers;
    if(Array.isArray(data.invoiceProducts)) invoiceProducts = data.invoiceProducts;
    if(Array.isArray(data.estimateProducts)) estimateProducts = data.estimateProducts;
    if(Array.isArray(data.godowns)) godowns = data.godowns;
    if(Array.isArray(data.purchases)) purchases = data.purchases;
    if(data.stockLedger) stockLedger = data.stockLedger;
    if(Array.isArray(data.vehicles)) vehicles = data.vehicles;
    if(Array.isArray(data.transfers)) transfers = data.transfers;
    if(data.purchaseCounter) purchaseCounter = data.purchaseCounter;
    if(data.transferCounter) transferCounter = data.transferCounter;
  }

  function saveAll(){
    try{
      localStorage.setItem(KEY, JSON.stringify(snapshot()));
      setStatus("Saved locally"); showToast("Saved locally");
    }catch(err){ alert("Local save failed: " + err.message); }
  }

  function loadAll(){
    try{
      const raw = localStorage.getItem(KEY);
      if(!raw){ setStatus("Local DB Ready"); return; }
      apply(JSON.parse(raw));
      setStatus("Loaded local data");
    }catch(err){ console.warn(err); setStatus("Local load failed"); }
  }

  function clearAll(){
    if(!confirm("Clear saved local database?")) return;
    localStorage.removeItem(KEY);
    setStatus("Local data cleared"); showToast("Local data cleared");
  }

  function exportBackup(){
    const blob = new Blob([JSON.stringify(snapshot(), null, 2)], {type:"application/json"});
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "crackers_erp_backup_" + new Date().toISOString().slice(0,10) + ".json";
    a.click();
    URL.revokeObjectURL(url);
    setStatus("Backup exported"); showToast("Backup exported");
  }

  function importBackup(event){
    const file = event.target.files[0];
    if(!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      try{
        apply(JSON.parse(reader.result));
        saveAll();
        ERPRefresh.all();
        setStatus("Backup imported"); showToast("Backup imported");
      }catch(err){ alert("Invalid backup file: " + err.message); }
    };
    reader.readAsText(file);
    event.target.value = "";
  }

  return {saveAll, loadAll, clearAll, exportBackup, importBackup, setStatus};
})();

const ERPRefresh = {
  all(){
    renderCustomers();renderProducts();renderGodowns();renderVehicles();renderVehicleDriverDraft();
    refreshPurchaseLists();refreshTransferMasters();refreshActiveProductDatalist();
    renderPurchaseHistory();renderStockTable();renderTransferHistory();renderAllReports();
ensureDefaultProductRow();
    updateInvoiceNumber();updatePurchaseNo();updateTransferNo();calculateTotal();
  }
};

function autoSaveERP(){ ERPStorage.saveAll(); }

let currentType = "INV";
const counters = {
  INV:{SGFI:1,RET:1,WHOLESALE:1,EXPORT:1},
  EST:{SGFI:1,RET:1,WHOLESALE:1,EXPORT:1},
  PRO:{SGFI:1,RET:1,WHOLESALE:1,EXPORT:1}
};
let invoiceRecords = [];
let customers=[
  {name:"Nataraja H K",mobile:"",reference:"",address:"S/O Kadaveerappa, Kumbar Beedi, Holehonnuru",state:"Karnataka",pincode:"577227",id:"610763488392",gstin:""},
  {name:"Arun Agencies",mobile:"9876543210",reference:"Direct",address:"Sivakasi, Tamil Nadu",state:"Tamil Nadu",pincode:"626123",id:"",gstin:"33ABCDE1234F1Z5"}
];
let invoiceProducts=[
  {code:"INV001",name:"Mulli Colour Fountain",hsn:"3604",tax:18,rate:2000,unitQty:1,unit:"Case",status:"Active"},
  {code:"INV002",name:"Flower Pots Big",hsn:"3604",tax:18,rate:1500,unitQty:1,unit:"Box",status:"Active"},
  {code:"INV003",name:"Ground Chakkar Special",hsn:"3604",tax:18,rate:850,unitQty:1,unit:"Box",status:"Active"}
];
let estimateProducts=[
  {code:"EP001",name:"Mulli Colour Fountain - Estimate",hsn:"3604",tax:18,rate:1950,unitQty:1,unit:"Case",status:"Active"},
  {code:"EP002",name:"Sparklers 10 cm",hsn:"3604",tax:18,rate:300,unitQty:10,unit:"Box",status:"Active"},
  {code:"EP003",name:"Rocket Bomb",hsn:"3604",tax:18,rate:1250,unitQty:1,unit:"Box",status:"Active"}
];

function limitHSN(input){input.value=input.value.replace(/\D/g,"").slice(0,10)}
function rupee(v){return "₹"+Number(v||0).toLocaleString("en-IN",{minimumFractionDigits:2,maximumFractionDigits:2})}
function setTheme(type){
  const r=document.documentElement;
  const themes={
    INV:["#ff6b6b","#c24141","#fff1f2"],
    EST:["#4f8cff","#1e40af","#eff6ff"],
    PRO:["#9b6dff","#5b21b6","#f5f3ff"],
    MASTER:["#22c55e","#166534","#f0fdf4"]
  }[type];
  r.style.setProperty("--active",themes[0]);r.style.setProperty("--active-dark",themes[1]);r.style.setProperty("--active-soft",themes[2]);
}
function switchTab(pageId,btn,type){
  document.querySelectorAll(".page").forEach(p=>p.classList.remove("active"));
  document.getElementById(pageId).classList.add("active");
  document.querySelectorAll(".tab").forEach(t=>t.classList.remove("active"));
  btn.classList.add("active");
  if(type==="MASTER"){setTheme("MASTER");document.getElementById("docBadge").innerText =
      pageId === "productMasterPage" ? "PRODUCT MASTER" :
      pageId === "godownMasterPage" ? "GODOWN MASTER" :
      pageId === "vehicleMasterPage" ? "VEHICLE MASTER" :
      pageId === "purchaseEntryPage" ? "PURCHASE ENTRY" :
      pageId === "stockTransferPage" ? "STOCK TRANSFER" :
      pageId === "godownStockPage" ? "GODOWN STOCK" :
      pageId === "reportsPage" ? "REPORTS" :
      "CUSTOMER MASTER";
    return}
  currentType=type;setTheme(type);updateInvoiceNumber();refreshActiveProductDatalist();resetRows();
}
function updateInvoiceNumber(){
  const s=document.getElementById("invoiceSeries").value;
  const n=String(counters[currentType][s]).padStart(4,"0");
  document.getElementById("invoiceNo").value=s+"-"+n;
  const label=currentType==="INV"?"INVOICE":currentType==="EST"?"ESTIMATE":"PERFORMA";
  document.getElementById("docBadge").innerText=label+" • "+s+"-"+n;
}
function getActiveProductList(){return currentType==="INV"?invoiceProducts:estimateProducts}
function refreshActiveProductDatalist(){
  document.getElementById("activeProducts").innerHTML=getActiveProductList().filter(p=>p.status==="Active").map(p=>`<option value="${p.name}"></option>`).join("");
  document.getElementById("productListInfo").innerText=currentType==="INV"?"Using Invoice Product List • Tax fields enabled":"Using Estimate / Performa Product List • No tax fields • Amount = Cases × Quantity × Rate";
}

function rowHtml(i){
  return `<div><label>S.No</label><input value="${i}" readonly></div>
  <div><label>Product</label><input class="productName" list="activeProducts" placeholder="Type / select product"></div>
  <div class="hsn-field"><label>HSN</label><input class="hsn" value="3604" maxlength="10" oninput="limitHSN(this)"></div>
  <div class="tax-field"><label>Tax %</label><select class="taxRate"><option value="0">0%</option><option value="5">5%</option><option value="18" selected>18%</option><option value="40">40%</option><option value="12">12% Legacy</option><option value="28">28% Legacy</option></select></div>
  <div class="estimate-case-field"><label>No. of Cases</label><input class="cases" type="number" value="1"></div>
  <div><label>Quantity</label><input class="qty" type="number" value="1"></div>
  <div><label>Rate</label><input class="rate" type="number" value="0"></div>
  <div><label>Per</label><select class="per"><option>Case</option><option>Box</option><option>Pcs</option><option>Bundle</option></select></div>
  <div><label>Amount</label><input class="amount" readonly value="0"></div>
  <div class="row-actions"><button type="button" class="primary" onclick="addRow()">+</button><button type="button" class="danger" onclick="removeRow(this)">-</button></div>`;
}

function bindRow(row){
  if(row.dataset.bound === "1") return;
  row.dataset.bound = "1";

  const productInput = row.querySelector(".productName");
  if(productInput){
    productInput.addEventListener("input", e => fillProductDetails(e.target));
    productInput.addEventListener("change", e => fillProductDetails(e.target));
  }

  [".cases",".qty",".rate",".taxRate",".per"].forEach(sel=>{
    const el = row.querySelector(sel);
    if(el){
      el.addEventListener("input",()=>calculateRow(row));
      el.addEventListener("change",()=>calculateRow(row));
    }
  });
}

function addRow(){
  const rows = document.getElementById("rows");
  if(!rows){
    alert("Product entry area not found.");
    return;
  }

  const div = document.createElement("div");
  div.className = "product-row";
  div.innerHTML = rowHtml(rows.children.length + 1);
  rows.appendChild(div);

  bindRow(div);
  updateEstimateColumns();
  calculateRow(div);
  calculateTotal();
}

function removeRow(btn){
  const allRows = document.querySelectorAll(".product-row");
  if(allRows.length === 1){
    alert("At least one product row required");
    return;
  }

  btn.closest(".product-row").remove();
  renumberRows();
  calculateTotal();
}

function renumberRows(){
  document.querySelectorAll(".product-row").forEach((r,i)=>{
    const firstInput = r.querySelector("input");
    if(firstInput) firstInput.value = i + 1;
  });
}

function resetRows(){
  const rows = document.getElementById("rows");
  if(!rows) return;

  if(rows.children.length === 0){
    addRow();
  }else{
    document.querySelectorAll(".product-row").forEach(row=>bindRow(row));
    renumberRows();
    updateEstimateColumns();
    document.querySelectorAll(".product-row").forEach(row=>calculateRow(row));
  }

  const chargeRows = document.getElementById("additionalChargeRows");
  if(chargeRows && chargeRows.children.length === 0 && typeof addChargeRow === "function"){
    addChargeRow();
  }

  calculateTotal();
}

function updateEstimateColumns(){
  const est=currentType==="EST"||currentType==="PRO";
  document.body.classList.toggle("no-tax-mode", est);
  document.querySelectorAll(".estimate-case-field").forEach(el=>el.style.display=est?"block":"none");
  ensureAdditionalChargeRow();
  document.querySelectorAll(".product-row").forEach(r=>{
    r.style.gridTemplateColumns=est
      ?"65px 1.5fr 115px 105px 100px 115px auto"
      :"65px 1.5fr 95px 90px 0px 105px 100px 115px auto";
  });
}
function fillProductDetails(input){
  const p=getActiveProductList().find(x=>x.name.toLowerCase()===input.value.trim().toLowerCase());
  const row=input.closest(".product-row"); if(!p||!row)return;
  row.querySelector(".hsn").value=String(p.hsn||"3604").slice(0,10);
  row.querySelector(".taxRate").value=String(p.tax||18);
  row.querySelector(".qty").value=p.unitQty||1;
  row.querySelector(".rate").value=p.rate||0;
  row.querySelector(".per").value=p.unit||"Case";
  calculateRow(row);
}
function calculateRow(row){
  const cases=Number(row.querySelector(".cases").value||0);
  const qty=Number(row.querySelector(".qty").value||0);
  const rate=Number(row.querySelector(".rate").value||0);
  let amt=qty*rate;
  if(currentType==="EST"||currentType==="PRO")amt=cases*qty*rate;
  row.querySelector(".amount").value=amt.toFixed(2);
  calculateTotal();
}




function calculateTotal(){
  let subtotal=0,tax=0;
  let taxRates = [];
  const isTaxDocument = currentType === "INV";

  document.querySelectorAll(".product-row").forEach(row=>{
    const amt=Number(row.querySelector(".amount").value||0);
    const rate=Number(row.querySelector(".taxRate").value||0);
    subtotal+=amt;
    if(isTaxDocument){
      tax+=amt*rate/100;
      if(amt > 0 && !taxRates.includes(rate)) taxRates.push(rate);
    }
  });

  if(!isTaxDocument){
    const additionalCharges = calculateAdditionalCharges(subtotal);
    document.getElementById("cgstText").innerText=rupee(0);
    document.getElementById("sgstText").innerText=rupee(0);
    document.getElementById("subtotalText").innerText=rupee(subtotal);
    document.getElementById("discountText").innerText=rupee(0);
    if(document.getElementById("additionalChargesText")){
      document.getElementById("additionalChargesText").innerText=rupee(additionalCharges);
    }
    document.getElementById("grandTotalText").innerText=rupee(subtotal + additionalCharges);
    return;
  }

  const state=(document.getElementById("billState").value||"").trim().toLowerCase();
  const tn=state==="tamil nadu"||state==="tamilnadu"||state==="tn";
  const taxText = taxRates.length === 1 ? taxRates[0] : (taxRates.length > 1 ? "Mixed" : 18);

  if(tn){
    const halfText = taxRates.length === 1 ? (taxRates[0] / 2) : "Mixed";
    document.getElementById("taxLabel1").innerText = `CGST ${halfText}%`;
    document.getElementById("taxLabel2").innerText = `SGST ${halfText}%`;
    document.getElementById("cgstText").innerText=rupee(tax/2);
    document.getElementById("sgstText").innerText=rupee(tax/2);
  }else{
    document.getElementById("taxLabel1").innerText = `IGST ${taxText}%`;
    document.getElementById("taxLabel2").innerText = "CGST / SGST";
    document.getElementById("cgstText").innerText=rupee(tax);
    document.getElementById("sgstText").innerText=rupee(0);
  }

  document.getElementById("subtotalText").innerText=rupee(subtotal);
  document.getElementById("discountText").innerText=rupee(0);
  if(document.getElementById("additionalChargesText")){
    document.getElementById("additionalChargesText").innerText=rupee(0);
  }
  if(document.getElementById("additionalChargesText")){
    document.getElementById("additionalChargesText").innerText=rupee(0);
  }
  document.getElementById("grandTotalText").innerText=rupee(subtotal+tax);
}

function getCurrentBillingAmounts(){
  let subtotal=0,tax=0;
  document.querySelectorAll(".product-row").forEach(row=>{
    const amt=Number(row.querySelector(".amount")?.value||0);
    const rate=Number(row.querySelector(".taxRate")?.value||0);
    subtotal+=amt;
    if(currentType==="INV") tax+=amt*rate/100;
  });

  const state=(document.getElementById("billState").value||"").trim().toLowerCase();
  const tn=state==="tamil nadu"||state==="tamilnadu"||state==="tn";

  return {
    subtotal,
    tax,
    cgst: currentType==="INV" && tn ? tax/2 : 0,
    sgst: currentType==="INV" && tn ? tax/2 : 0,
    igst: currentType==="INV" && !tn ? tax : 0,
    grandTotal: subtotal+tax
  };
}

function saveBillingDocument(){
  if(currentType !== "INV"){
    alert("Estimate / Performa are non-tax documents. Use Additional Charges if required.");
    return;
  }

  const series = invoiceSeries.value;
  const number = invoiceNo.value;
  const amounts = getCurrentBillingAmounts();

  const record = {
    series,
    number,
    date: invoiceDate.value,
    customer: billCustomerName.value.trim(),
    state: billState.value,
    subtotal: amounts.subtotal,
    cgst: amounts.cgst,
    sgst: amounts.sgst,
    igst: amounts.igst,
    tax: amounts.tax,
    grandTotal: amounts.grandTotal,
    savedAt: new Date().toISOString()
  };

  const index = invoiceRecords.findIndex(r=>r.number===number);
  if(index>=0) invoiceRecords[index]=record;
  else invoiceRecords.push(record);

  counters.INV[series] += 1;
  updateInvoiceNumber();
  if(typeof autoSaveERP === "function") autoSaveERP();
  alert("Invoice tax record saved successfully.");
}

function chargeRowHtml(index){
  return `
    <div><label>S.No</label><input value="${index}" readonly></div>
    <div><label>Charge Name</label><input class="chargeName" placeholder="Packing / Loading / Invoice Tax"></div>
    <div><label>Source</label><select class="chargeSource"><option value="MANUAL">Manual</option><option value="INVOICE_TAX">Invoice Tax</option></select></div>
    <div><label>Add/Deduct</label><select class="chargeMode"><option value="ADD">Add</option><option value="DEDUCT">Deduct</option></select></div>
    <div><label>Type</label><select class="chargeType"><option value="AMOUNT">Exact Amount</option><option value="PERCENT">Percentage</option></select></div>
    <div><label>Value</label><input class="chargeValue" type="number" value="0"></div>
    <div><label>Inv Series</label><select class="invoiceTaxSeries"><option value="SGFI">SGFI</option><option value="RET">RET</option><option value="WHOLESALE">WHOLESALE</option><option value="EXPORT">EXPORT</option></select></div>
    <div><label>Inv No</label><input class="invoiceTaxNo" placeholder="0001 / SGFI-0001"></div>
    <div><label>Amount</label><input class="chargeAmount" readonly value="0"></div>
    <div class="charge-actions"><button type="button" class="primary" onclick="fetchInvoiceTaxForRow(this)">Fetch</button><button type="button" class="primary" onclick="addChargeRow()">+</button><button type="button" class="danger" onclick="removeChargeRow(this)">-</button></div>
  `;
}

function bindChargeRow(row){
  if(row.dataset.chargeBound === "1") return;
  row.dataset.chargeBound = "1";

  [".chargeName",".chargeSource",".chargeMode",".chargeType",".chargeValue",".invoiceTaxSeries",".invoiceTaxNo"].forEach(sel=>{
    const el = row.querySelector(sel);
    if(el){
      el.addEventListener("input", calculateTotal);
      el.addEventListener("change", calculateTotal);
    }
  });
}

function addChargeRow(){
  const rows = document.getElementById("additionalChargeRows");
  if(!rows) return;
  const div = document.createElement("div");
  div.className = "charge-row";
  div.innerHTML = chargeRowHtml(rows.children.length + 1);
  rows.appendChild(div);
  bindChargeRow(div);
  calculateTotal();
}

function removeChargeRow(btn){
  const rows = document.querySelectorAll(".charge-row");
  if(rows.length <= 1){
    const row = btn.closest(".charge-row");
    row.querySelector(".chargeName").value = "";
    row.querySelector(".chargeValue").value = "0";
    row.querySelector(".chargeAmount").value = "0";
    calculateTotal();
    return;
  }

  btn.closest(".charge-row").remove();
  renumberChargeRows();
  calculateTotal();
}

function renumberChargeRows(){
  document.querySelectorAll(".charge-row").forEach((row,index)=>{
    const firstInput = row.querySelector("input");
    if(firstInput) firstInput.value = index + 1;
  });
}

function fetchInvoiceTaxForRow(btn){
  const row = btn.closest(".charge-row");
  if(!row) return;

  row.querySelector(".chargeSource").value = "INVOICE_TAX";

  const series = row.querySelector(".invoiceTaxSeries").value;
  const entered = row.querySelector(".invoiceTaxNo").value.trim();

  if(!entered){
    alert("Enter invoice number first.");
    return;
  }

  const invoiceNumber = entered.includes("-") ? entered : `${series}-${entered.padStart(4,"0")}`;
  const record = invoiceRecords.find(r=>r.number===invoiceNumber);

  if(!record){
    alert("Invoice tax record not found. First save that invoice.");
    return;
  }

  row.querySelector(".chargeName").value = "Invoice Tax " + record.number;
  row.querySelector(".chargeMode").value = "ADD";
  row.querySelector(".chargeType").value = "AMOUNT";
  row.querySelector(".chargeValue").value = Number(record.tax||0).toFixed(2);
  row.querySelector(".chargeAmount").value = Number(record.tax||0).toFixed(2);
  calculateTotal();
}

function calculateAdditionalCharges(subtotal){
  if(currentType === "INV") return 0;

  let totalCharges = 0;

  document.querySelectorAll(".charge-row").forEach(row=>{
    const name = row.querySelector(".chargeName").value.trim();
    const mode = row.querySelector(".chargeMode").value;
    const type = row.querySelector(".chargeType").value;
    const value = Number(row.querySelector(".chargeValue").value || 0);

    let amount = 0;
    if(name || value){
      amount = type === "PERCENT" ? (subtotal * value / 100) : value;
      if(mode === "DEDUCT") amount = -amount;
    }

    row.querySelector(".chargeAmount").value = amount.toFixed(2);
    totalCharges += amount;
  });

  return totalCharges;
}

function ensureAdditionalChargeRow(){
  const rows = document.getElementById("additionalChargeRows");
  if(rows && rows.children.length === 0){
    addChargeRow();
  }
}

function saveCustomer(){
  const c={name:masterName.value.trim(),mobile:masterMobile.value.trim(),reference:masterReference.value.trim(),address:masterAddress.value.trim(),state:masterState.value.trim(),pincode:masterPincode.value.trim(),id:masterId.value.trim(),gstin:masterGstin.value.trim()};
  if(!c.name){alert("Customer name is required");return}
  const i=customers.findIndex(x=>x.name.toLowerCase()===c.name.toLowerCase());
  if(i>=0)customers[i]=c;else customers.push(c);
  customerMessage.innerText=i>=0?"Customer updated successfully.":"Customer saved successfully.";
  renderCustomers();clearCustomerMaster(false);autoSaveERP();
}
function clearCustomerMaster(msg=true){["masterName","masterMobile","masterReference","masterAddress","masterState","masterPincode","masterId","masterGstin"].forEach(id=>document.getElementById(id).value="");if(msg)customerMessage.innerText=""}
function editCustomer(i){const c=customers[i];masterName.value=c.name;masterMobile.value=c.mobile;masterReference.value=c.reference;masterAddress.value=c.address;masterState.value=c.state;masterPincode.value=c.pincode;masterId.value=c.id;masterGstin.value=c.gstin}
function deleteCustomer(i){if(confirm("Delete this customer?")){customers.splice(i,1);renderCustomers()}}
function renderCustomers(){
  customerTableBody.innerHTML=customers.map((c,i)=>`<tr><td>${c.name}</td><td>${c.mobile}</td><td>${c.state}</td><td>${c.gstin}</td><td>${c.reference}</td><td><button class="secondary" onclick="editCustomer(${i})">Edit</button> <button class="danger" onclick="deleteCustomer(${i})">Delete</button></td></tr>`).join("");
  customerNames.innerHTML=customers.map(c=>`<option value="${c.name}"></option>`).join("");
}
function loadCustomerToBilling(){
  const c=customers.find(x=>x.name.toLowerCase()===billCustomerName.value.trim().toLowerCase()); if(!c)return;
  billAddress.value=c.address;billState.value=c.state;billPincode.value=c.pincode;billId.value=c.id;billGstin.value=c.gstin;billMobile.value=c.mobile;billReference.value=c.reference;calculateTotal();
}
function saveProduct(){
  const type=productListType.value;
  const p={code:masterProductCode.value.trim()||autoProductCode(type),name:masterProductName.value.trim(),hsn:(masterProductHsn.value.trim()||"3604").slice(0,10),tax:Number(masterProductTax.value||18),rate:Number(masterProductRate.value||0),unitQty:Number(masterProductUnitQty.value||1),unit:masterProductUnit.value,status:masterProductStatus.value};
  if(!p.name){alert("Product name is required");return}
  const list=type==="INV"?invoiceProducts:estimateProducts;
  const i=list.findIndex(x=>x.code.toLowerCase()===p.code.toLowerCase());
  if(i>=0)list[i]=p;else list.push(p);
  productMessage.innerText=i>=0?"Product updated successfully.":"Product saved successfully.";
  renderProducts();refreshActiveProductDatalist();clearProductMaster(false);autoSaveERP();
}
function autoProductCode(type){const list=type==="INV"?invoiceProducts:estimateProducts;return (type==="INV"?"INV":"EP")+String(list.length+1).padStart(3,"0")}
function clearProductMaster(msg=true){masterProductCode.value="";masterProductName.value="";masterProductHsn.value="3604";masterProductTax.value="18";masterProductRate.value="0";masterProductUnitQty.value="1";masterProductUnit.value="Case";masterProductStatus.value="Active";if(msg)productMessage.innerText=""}
function editProduct(type,i){const p=(type==="INV"?invoiceProducts:estimateProducts)[i];productListType.value=type;masterProductCode.value=p.code;masterProductName.value=p.name;masterProductHsn.value=String(p.hsn||"3604").slice(0,10);masterProductTax.value=String(p.tax||18);masterProductRate.value=p.rate;masterProductUnitQty.value=p.unitQty||1;masterProductUnit.value=p.unit;masterProductStatus.value=p.status}
function deleteProduct(type,i){if(!confirm("Delete this product?"))return;(type==="INV"?invoiceProducts:estimateProducts).splice(i,1);renderProducts();refreshActiveProductDatalist()}
function renderProducts(){
  invoiceProductTable.innerHTML=invoiceProducts.map((p,i)=>`<tr><td>${p.code}</td><td>${p.name}</td><td>${p.hsn}</td><td>${p.tax}%</td><td>${rupee(p.rate)}</td><td>${p.unitQty}</td><td>${p.unit}</td><td><button class="secondary" onclick="editProduct('INV',${i})">Edit</button> <button class="danger" onclick="deleteProduct('INV',${i})">Delete</button></td></tr>`).join("");
  estimateProductTable.innerHTML=estimateProducts.map((p,i)=>`<tr><td>${p.code}</td><td>${p.name}</td><td>${p.hsn}</td><td>${p.tax}%</td><td>${rupee(p.rate)}</td><td>${p.unitQty}</td><td>${p.unit}</td><td><button class="secondary" onclick="editProduct('EP',${i})">Edit</button> <button class="danger" onclick="deleteProduct('EP',${i})">Delete</button></td></tr>`).join("");
}

let godowns = [
  {name:"Main Godown"},
  {name:"Fancy Items Godown"}
];

function saveGodown(){
  const name = godownName.value.trim();
  if(!name){ alert("Godown name is required"); godownName.focus(); return; }
  const item = {name};
  const existingIndex = godowns.findIndex(g => g.name.toLowerCase() === name.toLowerCase());
  if(existingIndex >= 0){
    godowns[existingIndex] = item;
    godownMessage.innerText = "Godown updated successfully.";
  }else{
    godowns.push(item);
    godownMessage.innerText = "Godown saved successfully.";
  }
  renderGodowns();
  clearGodownMaster(false);
  autoSaveERP();
}

function clearGodownMaster(clearMessage=true){
  godownName.value = "";
  if(clearMessage) godownMessage.innerText = "";
}

function editGodown(index){
  const g = godowns[index];
  godownName.value = g.name;
  godownMessage.innerText = "Editing godown: " + g.name;
}

function deleteGodown(index){
  if(!confirm("Delete this godown?")) return;
  godowns.splice(index,1);
  renderGodowns();
}

function renderGodowns(){
  godownTableBody.innerHTML = godowns.map((g,index)=>`
    <tr>
      <td>${g.name}</td>
      <td>
        <button class="secondary" onclick="editGodown(${index})">Edit</button>
        <button class="danger" onclick="deleteGodown(${index})">Delete</button>
      </td>
    </tr>
  `).join("");
  refreshPurchaseLists();
  refreshTransferMasters();
  document.querySelectorAll(".transfer-row").forEach(row=>populateTransferRowGodowns(row));
}



let purchaseCounter = 1;
let purchases = [];
let stockLedger = {};

function getAllProducts(){
  return [...invoiceProducts, ...estimateProducts];
}

function refreshPurchaseLists(){
  allProductsList.innerHTML = getAllProducts().map(p=>`<option value="${p.name}"></option>`).join("");
  godownList.innerHTML = godowns.map(g=>`<option value="${g.name}"></option>`).join("");

  const current = stockFilterGodown ? stockFilterGodown.value : "";
  if(stockFilterGodown){
    stockFilterGodown.innerHTML = `<option value="">All Godowns</option>` + godowns.map(g=>`
      <option value="${g.name}">${g.name}</option>
    `).join("");
    stockFilterGodown.value = current;
  }
}

function updatePurchaseNo(){
  purchaseNo.value = "PUR-" + String(purchaseCounter).padStart(4,"0");
}

function purchaseRowHtml(index){
  return `
    <div><label>S.No</label><input value="${index}" readonly></div>

    <div>
      <label>Product</label>
      <input class="purchaseProductName" list="allProductsList" placeholder="Select product">
    </div>

    <div>
      <label>Godown</label>
      <input class="purchaseGodown" list="godownList" placeholder="Godown no">
    </div>

    <div>
      <label>HSN</label>
      <input class="purchaseHsn" readonly>
    </div>

    <div>
      <label>Qty</label>
      <input class="purchaseQty" type="number" value="1">
    </div>

    <div>
      <label>Rate</label>
      <input class="purchaseRate" type="number" value="0">
    </div>

    <div>
      <label>Amount</label>
      <input class="purchaseAmount" readonly value="0">
    </div>

    <div style="display:flex;gap:8px">
      <button type="button" class="primary" onclick="addPurchaseRow()">+</button>
      <button type="button" class="danger" onclick="removePurchaseRow(this)">-</button>
    </div>
  `;
}

function bindPurchaseRow(row){
  const productInput = row.querySelector(".purchaseProductName");
  const qtyInput = row.querySelector(".purchaseQty");
  const rateInput = row.querySelector(".purchaseRate");

  productInput.addEventListener("input", ()=>{
    fillPurchaseProduct(row);
  });

  productInput.addEventListener("change", ()=>{
    fillPurchaseProduct(row);
  });

  [qtyInput, rateInput].forEach(el=>{
    el.addEventListener("input", ()=>calculatePurchaseRow(row));
    el.addEventListener("change", ()=>calculatePurchaseRow(row));
  });
}

function addPurchaseRow(){
  const rows = purchaseRows;
  const div = document.createElement("div");
  div.className = "purchase-row";
  div.innerHTML = purchaseRowHtml(rows.children.length + 1);
  rows.appendChild(div);
  bindPurchaseRow(div);
  calculatePurchaseTotals();
}

function removePurchaseRow(btn){
  if(document.querySelectorAll(".purchase-row").length === 1){
    alert("At least one purchase row required");
    return;
  }

  btn.closest(".purchase-row").remove();
  renumberPurchaseRows();
  calculatePurchaseTotals();
}

function renumberPurchaseRows(){
  document.querySelectorAll(".purchase-row").forEach((row,index)=>{
    row.querySelector("input").value = index + 1;
  });
}

function fillPurchaseProduct(row){
  const name = row.querySelector(".purchaseProductName").value.trim().toLowerCase();
  const product = getAllProducts().find(p=>p.name.toLowerCase() === name);

  if(!product) return;

  row.querySelector(".purchaseHsn").value = product.hsn || "3604";
  row.querySelector(".purchaseRate").value = product.rate || 0;
  calculatePurchaseRow(row);
}

function calculatePurchaseRow(row){
  const qty = Number(row.querySelector(".purchaseQty").value || 0);
  const rate = Number(row.querySelector(".purchaseRate").value || 0);
  row.querySelector(".purchaseAmount").value = (qty * rate).toFixed(2);
  calculatePurchaseTotals();
}

function calculatePurchaseTotals(){
  let qtyTotal = 0;
  let valueTotal = 0;
  let itemCount = 0;

  document.querySelectorAll(".purchase-row").forEach(row=>{
    const product = row.querySelector(".purchaseProductName").value.trim();
    const qty = Number(row.querySelector(".purchaseQty").value || 0);
    const amount = Number(row.querySelector(".purchaseAmount").value || 0);

    if(product) itemCount += 1;
    qtyTotal += qty;
    valueTotal += amount;
  });

  purchaseQtyTotal.innerText = qtyTotal;
  purchaseValueTotal.innerText = rupee(valueTotal);
  purchaseItemCount.innerText = itemCount;
}

function parseGodownNo(value){
  return (value || "").split(" - ")[0].trim();
}

function savePurchaseEntry(){
  const rows = Array.from(document.querySelectorAll(".purchase-row"));
  const items = [];

  for(const row of rows){
    const productName = row.querySelector(".purchaseProductName").value.trim();
    const godownNo = parseGodownNo(row.querySelector(".purchaseGodown").value.trim());
    const hsn = row.querySelector(".purchaseHsn").value.trim();
    const qty = Number(row.querySelector(".purchaseQty").value || 0);
    const rate = Number(row.querySelector(".purchaseRate").value || 0);
    const amount = Number(row.querySelector(".purchaseAmount").value || 0);

    if(!productName) continue;

    if(!godownNo){
      alert("Please select godown for " + productName);
      return;
    }

    if(qty <= 0){
      alert("Enter valid quantity for " + productName);
      return;
    }

    const product = getAllProducts().find(p=>p.name.toLowerCase() === productName.toLowerCase());

    items.push({
      productName,
      productCode: product ? product.code : "",
      hsn: hsn || (product ? product.hsn : "3604"),
      tax: product ? product.tax : 18,
      unit: product ? product.unit : "Case",
      godownNo,
      qty,
      rate,
      amount
    });
  }

  if(items.length === 0){
    alert("Add at least one purchase item");
    return;
  }

  const purchase = {
    no: purchaseNo.value,
    date: purchaseDate.value,
    supplier: supplierName.value.trim(),
    billNo: supplierBillNo.value.trim(),
    items
  };

  purchases.push(purchase);

  items.forEach(item=>{
    const key = item.godownNo + "||" + item.productName;

    if(!stockLedger[key]){
      stockLedger[key] = {
        godownNo:item.godownNo,
        productCode:item.productCode,
        productName:item.productName,
        hsn:item.hsn,
        tax:item.tax,
        unit:item.unit,
        qty:0,
        value:0,
        avgRate:0
      };
    }

    stockLedger[key].qty += item.qty;
    stockLedger[key].value += item.amount;
    stockLedger[key].avgRate = stockLedger[key].qty
      ? stockLedger[key].value / stockLedger[key].qty
      : 0;
  });

  purchaseCounter += 1;
  renderPurchaseHistory();
  renderStockTable();
  clearPurchaseEntry();

  purchaseMessage.innerText = "Purchase saved and godown stock updated successfully.";
  autoSaveERP();
}

function clearPurchaseEntry(){
  supplierName.value = "";
  supplierBillNo.value = "";
  purchaseMessage.innerText = "";
  updatePurchaseNo();
  purchaseRows.innerHTML = "";
  addPurchaseRow();
  calculatePurchaseTotals();
}

function renderPurchaseHistory(){
  purchaseHistoryBody.innerHTML = purchases.map(p=>{
    const qty = p.items.reduce((sum,i)=>sum+i.qty,0);
    const value = p.items.reduce((sum,i)=>sum+i.amount,0);

    return `
      <tr>
        <td>${p.no}</td>
        <td>${p.date}</td>
        <td>${p.supplier}</td>
        <td>${p.billNo}</td>
        <td>${p.items.length}</td>
        <td>${qty}</td>
        <td>${rupee(value)}</td>
      </tr>
    `;
  }).join("");
}

function renderStockTable(){
  const godownFilter = stockFilterGodown ? stockFilterGodown.value : "";
  const search = stockSearchProduct ? stockSearchProduct.value.trim().toLowerCase() : "";

  let rows = Object.values(stockLedger);

  if(godownFilter){
    rows = rows.filter(r=>r.godownNo === godownFilter);
  }

  if(search){
    rows = rows.filter(r=>r.productName.toLowerCase().includes(search));
  }

  let totalValue = 0;

  stockTableBody.innerHTML = rows.map(r=>{
    totalValue += r.value;

    const godown = godowns.find(g=>g.name === r.godownNo);
    const godownText = godown ? godown.name : r.godownNo;

    return `
      <tr>
        <td>${godownText}</td>
        <td>${r.productCode}</td>
        <td>${r.productName}</td>
        <td>${r.hsn}</td>
        <td>${r.tax}%</td>
        <td>${r.qty}</td>
        <td>${r.unit}</td>
        <td>${rupee(r.avgRate)}</td>
        <td>${rupee(r.value)}</td>
      </tr>
    `;
  }).join("");

  if(stockTotalValue){
    stockTotalValue.value = rupee(totalValue);
  }
}



let vehicles = [
  {no:"TN67AB1234", name:"Mini Truck", ownerName:"Arun", ownerPhone:"9876543210", drivers:[{name:"Murugan", phone:"9876500001"},{name:"Kumar", phone:"9876500002"}]},
  {no:"TN67CD5678", name:"Van", ownerName:"Bala", ownerPhone:"9123456780", drivers:[{name:"Ravi", phone:"9123400001"}]}
];
let vehicleDriverDraft = [];

let transferCounter = 1;
let transfers = [];

function addDriverToVehicle(){
  const name = vehicleDriverName.value.trim();
  const phone = vehicleDriverPhone.value.trim();
  if(!name){ alert("Driver name is required"); return; }
  vehicleDriverDraft.push({name, phone});
  vehicleDriverName.value = "";
  vehicleDriverPhone.value = "";
  renderVehicleDriverDraft();
}

function renderVehicleDriverDraft(){
  if(!vehicleDriversBox) return;
  if(!vehicleDriverDraft.length){ vehicleDriversBox.innerText = "No drivers added"; return; }
  vehicleDriversBox.innerHTML = vehicleDriverDraft.map((d,index)=>`
    <span style="display:inline-block;background:white;color:#166534;border-radius:999px;padding:6px 10px;margin:3px;">
      ${d.name} - ${d.phone || "No phone"}
      <button type="button" onclick="removeDriverDraft(${index})" style="padding:2px 6px;margin-left:6px;border-radius:8px;">x</button>
    </span>
  `).join("");
}

function removeDriverDraft(index){
  vehicleDriverDraft.splice(index,1);
  renderVehicleDriverDraft();
}

function saveVehicle(){
  const no = vehicleNo.value.trim().toUpperCase();
  const name = vehicleName.value.trim();
  const owner = ownerName.value.trim();
  const ownerNo = ownerPhone.value.trim();
  if(!no){ alert("Vehicle number is required"); return; }
  if(vehicleDriverDraft.length === 0){ alert("Add at least one driver"); return; }
  const item = {no, name, ownerName:owner, ownerPhone:ownerNo, drivers:[...vehicleDriverDraft]};
  const existingIndex = vehicles.findIndex(v => v.no.toLowerCase() === no.toLowerCase());
  if(existingIndex >= 0){ vehicles[existingIndex] = item; vehicleMessage.innerText = "Vehicle updated successfully."; }
  else{ vehicles.push(item); vehicleMessage.innerText = "Vehicle saved successfully."; }
  renderVehicles();
  refreshTransferMasters();
  clearVehicleMaster(false);
  autoSaveERP();
}

function clearVehicleMaster(clearMessage=true){
  vehicleNo.value = "";
  vehicleName.value = "";
  ownerName.value = "";
  ownerPhone.value = "";
  vehicleDriverName.value = "";
  vehicleDriverPhone.value = "";
  vehicleDriverDraft = [];
  renderVehicleDriverDraft();
  if(clearMessage) vehicleMessage.innerText = "";
}

function editVehicle(index){
  const v = vehicles[index];
  vehicleNo.value = v.no;
  vehicleName.value = v.name;
  ownerName.value = v.ownerName || "";
  ownerPhone.value = v.ownerPhone || "";
  vehicleDriverDraft = [...(v.drivers || [])];
  renderVehicleDriverDraft();
  vehicleMessage.innerText = "Editing vehicle: " + v.no;
}

function deleteVehicle(index){
  if(!confirm("Delete this vehicle?")) return;
  vehicles.splice(index,1);
  renderVehicles();
  refreshTransferMasters();
}

function renderVehicles(){
  vehicleTableBody.innerHTML = vehicles.map((v,index)=>`
    <tr>
      <td>${v.no}</td>
      <td>${v.name}</td>
      <td>${v.ownerName || ""}</td>
      <td>${v.ownerPhone || ""}</td>
      <td>${(v.drivers || []).map(d=>`${d.name} - ${d.phone || ""}`).join("<br>")}</td>
      <td>
        <button class="secondary" onclick="editVehicle(${index})">Edit</button>
        <button class="danger" onclick="deleteVehicle(${index})">Delete</button>
      </td>
    </tr>
  `).join("");
}

function updateTransferNo(){
  transferNo.value = "TRF-" + String(transferCounter).padStart(4,"0");
}

function refreshTransferMasters(){
  const godownOptions = godowns.map(g=>`<option value="${g.name}">${g.name}</option>`).join("");
  if(transferFromGodown) transferFromGodown.innerHTML = `<option value="">Select From Godown</option>` + godownOptions;
  if(transferToGodown) transferToGodown.innerHTML = `<option value="">Select To Godown</option>` + godownOptions;
  if(transferVehicle){
    transferVehicle.innerHTML = `<option value="">Select Vehicle</option>` + vehicles.map(v=>`<option value="${v.no}">${v.no} - ${v.name}</option>`).join("");
    transferVehicle.onchange = function(){
      const v = vehicles.find(item=>item.no === transferVehicle.value);
      transferVehicleText.innerText = v ? v.no : "-";
      renderTransferDrivers();
    };
  }
  renderTransferDrivers();
}

function renderTransferDrivers(){
  if(!transferDriver) return;
  const vehicle = vehicles.find(v=>v.no === transferVehicle.value);
  if(!vehicle){
    transferDriver.innerHTML = `<option value="">Select Driver</option>`;
    if(transferDriverPhone) transferDriverPhone.value = "";
    return;
  }
  transferDriver.innerHTML = `<option value="">Select Driver</option>` + (vehicle.drivers || []).map(d=>`<option value="${d.name}">${d.name}</option>`).join("");
  updateTransferDriverPhone();
}

function updateTransferDriverPhone(){
  const vehicle = vehicles.find(v=>v.no === transferVehicle.value);
  const driver = vehicle ? (vehicle.drivers || []).find(d=>d.name === transferDriver.value) : null;
  if(transferDriverPhone) transferDriverPhone.value = driver ? driver.phone : "";
}

function getStockItemsForGodown(godownNo){
  return Object.values(stockLedger).filter(item => item.godownNo === godownNo && item.qty > 0);
}

function refreshTransferProductOptions(row){
  const fromGodown = row.querySelector(".rowFromGodown").value;
  const products = getStockItemsForGodown(fromGodown);

  const input = row.querySelector(".transferProduct");
  const listId = "transferProductsList";
  let datalist = document.getElementById(listId);

  if(!datalist){
    datalist = document.createElement("datalist");
    datalist.id = listId;
    document.body.appendChild(datalist);
  }

  datalist.innerHTML = products.map(p=>`<option value="${p.productName}"></option>`).join("");
  input.setAttribute("list", listId);
}

function transferRowHtml(index){
  return `
    <div><label>S.No</label><input value="${index}" readonly></div>

    <div>
      <label>Product</label>
      <input class="transferProduct" placeholder="Select stock product">
    </div>

    <div>
      <label>From Godown</label>
      <select class="rowFromGodown"></select>
    </div>

    <div>
      <label>To Godown</label>
      <select class="rowToGodown"></select>
    </div>

    <div>
      <label>Available Qty</label>
      <input class="availableQty" readonly value="0">
    </div>

    <div>
      <label>Transfer Qty</label>
      <input class="transferQty" type="number" value="1">
    </div>

    <div>
      <label>Unit</label>
      <input class="transferUnit" readonly>
    </div>

    <div style="display:flex;gap:8px">
      <button type="button" class="primary" onclick="addTransferRow()">+</button>
      <button type="button" class="danger" onclick="removeTransferRow(this)">-</button>
    </div>
  `;
}

function populateTransferRowGodowns(row){
  const options = `<option value="">Select Godown</option>` + godowns.map(g=>`<option value="${g.name}">${g.name}</option>`).join("");
  row.querySelector(".rowFromGodown").innerHTML = options;
  row.querySelector(".rowToGodown").innerHTML = options;
}

function bindTransferRow(row){
  populateTransferRowGodowns(row);
  refreshTransferProductOptions(row);

  row.querySelector(".rowFromGodown").addEventListener("change", ()=>{
    row.querySelector(".transferProduct").value = "";
    row.querySelector(".availableQty").value = "0";
    row.querySelector(".transferUnit").value = "";
    refreshTransferProductOptions(row);
    calculateTransferTotals();
  });

  row.querySelector(".rowToGodown").addEventListener("change", calculateTransferTotals);

  row.querySelector(".transferProduct").addEventListener("input", ()=>{
    fillTransferProduct(row);
  });

  row.querySelector(".transferProduct").addEventListener("change", ()=>{
    fillTransferProduct(row);
  });

  row.querySelector(".transferQty").addEventListener("input", calculateTransferTotals);
}

function addTransferRow(){
  const div = document.createElement("div");
  div.className = "transfer-row";
  div.innerHTML = transferRowHtml(transferRows.children.length + 1);
  transferRows.appendChild(div);
  bindTransferRow(div);
  calculateTransferTotals();
}

function removeTransferRow(btn){
  if(document.querySelectorAll(".transfer-row").length === 1){
    alert("At least one transfer row required");
    return;
  }

  btn.closest(".transfer-row").remove();
  renumberTransferRows();
  calculateTransferTotals();
}

function renumberTransferRows(){
  document.querySelectorAll(".transfer-row").forEach((row,index)=>{
    row.querySelector("input").value = index + 1;
  });
}

function fillTransferProduct(row){
  const fromGodown = row.querySelector(".rowFromGodown").value;
  const name = row.querySelector(".transferProduct").value.trim().toLowerCase();
  const stock = getStockItemsForGodown(fromGodown).find(item=>item.productName.toLowerCase() === name);

  if(!stock) return;

  row.querySelector(".availableQty").value = stock.qty;
  row.querySelector(".transferUnit").value = stock.unit;
  calculateTransferTotals();
}

function calculateTransferTotals(){
  let totalQty = 0;
  let itemCount = 0;

  document.querySelectorAll(".transfer-row").forEach(row=>{
    const product = row.querySelector(".transferProduct").value.trim();
    const qty = Number(row.querySelector(".transferQty").value || 0);

    if(product) itemCount += 1;
    totalQty += qty;
  });

  transferQtyTotal.innerText = totalQty;
  transferItemCount.innerText = itemCount;
}

function clearTransferEntry(){
  transferRemarks.value = "";
  transferDriver.innerHTML = `<option value="">Select Driver</option>`;
  if(transferDriverPhone) transferDriverPhone.value = "";
  transferVehicleText.innerText = "-";
  transferMessage.innerText = "";
  updateTransferNo();
  transferRows.innerHTML = "";
  addTransferRow();
  calculateTransferTotals();
}

function saveStockTransfer(){
  const vehicleNo = transferVehicle.value;
  const driverName = transferDriver.value;

  if(!vehicleNo){
    alert("Select vehicle");
    return;
  }

  if(!driverName){
    alert("Select driver");
    return;
  }

  const items = [];

  for(const row of Array.from(document.querySelectorAll(".transfer-row"))){
    const productName = row.querySelector(".transferProduct").value.trim();
    const fromGodown = row.querySelector(".rowFromGodown").value;
    const toGodown = row.querySelector(".rowToGodown").value;
    const qty = Number(row.querySelector(".transferQty").value || 0);

    if(!productName) continue;

    if(!fromGodown || !toGodown){
      alert("Select From Godown and To Godown for " + productName);
      return;
    }

    if(fromGodown === toGodown){
      alert("From Godown and To Godown cannot be same for " + productName);
      return;
    }

    const sourceKey = fromGodown + "||" + productName;
    const sourceStock = stockLedger[sourceKey];

    if(!sourceStock || sourceStock.qty <= 0){
      alert("No stock available for " + productName + " in " + fromGodown);
      return;
    }

    if(qty <= 0){
      alert("Enter valid transfer qty for " + productName);
      return;
    }

    if(qty > sourceStock.qty){
      alert("Transfer qty exceeds available stock for " + productName);
      return;
    }

    items.push({
      productName,
      fromGodown,
      toGodown,
      qty,
      unit: sourceStock.unit,
      productCode: sourceStock.productCode,
      hsn: sourceStock.hsn,
      tax: sourceStock.tax,
      rate: sourceStock.avgRate,
      value: qty * sourceStock.avgRate
    });
  }

  if(items.length === 0){
    alert("Add at least one transfer item");
    return;
  }

  items.forEach(item=>{
    const sourceKey = item.fromGodown + "||" + item.productName;
    const destKey = item.toGodown + "||" + item.productName;

    const source = stockLedger[sourceKey];
    source.qty -= item.qty;
    source.value -= item.value;

    if(source.qty <= 0){
      source.qty = 0;
      source.value = 0;
      source.avgRate = item.rate;
    }else{
      source.avgRate = source.value / source.qty;
    }

    if(!stockLedger[destKey]){
      stockLedger[destKey] = {
        godownNo: item.toGodown,
        productCode: item.productCode,
        productName: item.productName,
        hsn: item.hsn,
        tax: item.tax,
        unit: item.unit,
        qty: 0,
        value: 0,
        avgRate: item.rate
      };
    }

    const dest = stockLedger[destKey];
    dest.qty += item.qty;
    dest.value += item.value;
    dest.avgRate = dest.qty ? dest.value / dest.qty : item.rate;
  });

  const vehicle = vehicles.find(v=>v.no === vehicleNo);

  transfers.push({
    no: transferNo.value,
    date: transferDate.value,
    vehicleNo,
    vehicleName: vehicle ? vehicle.name : "",
    driverName,
    driverPhone: transferDriverPhone ? transferDriverPhone.value : "",
    remarks: transferRemarks.value.trim(),
    items
  });

  transferCounter += 1;

  renderTransferHistory();
  renderStockTable();
  clearTransferEntry();
  transferMessage.innerText = "Product-wise godown transfer saved successfully.";
  autoSaveERP();
}

function renderTransferHistory(){
  transferHistoryBody.innerHTML = transfers.map(t=>{
    const qty = t.items.reduce((sum,i)=>sum+i.qty,0);
    const routes = [...new Set(t.items.map(i=>`${i.fromGodown} → ${i.toGodown}`))].join("<br>");

    return `
      <tr>
        <td>${t.no}</td>
        <td>${t.date}</td>
        <td>${routes}</td>
        <td>${t.vehicleNo}</td>
        <td>${t.driverName || ""}</td>
        <td>${t.items.length}</td>
        <td>${qty}</td>
      </tr>
    `;
  }).join("");
}





let suppliers = [];
let activeReport = "customer";

const reportFilterConfig = {
  customer: {
    title:"Customer Report",
    show:["search","type"],
    searchLabel:"Customer Search",
    searchPlaceholder:"Customer / mobile / GSTIN / state",
    typeLabel:"State",
    typeOptions:()=>uniqueOptions(customers.map(c=>c.state).filter(Boolean))
  },
  supplier: {
    title:"Supplier Report",
    show:["search","type"],
    searchLabel:"Supplier Search",
    searchPlaceholder:"Supplier / mobile / GSTIN / state",
    typeLabel:"Supplier Type",
    typeOptions:()=>uniqueOptions((typeof suppliers !== "undefined" ? suppliers : []).map(s=>s.type).filter(Boolean))
  },
  product: {
    title:"Product Report",
    show:["search","type"],
    searchLabel:"Product Search",
    searchPlaceholder:"Product / code / HSN",
    typeLabel:"Product List",
    typeOptions:()=>["Invoice","Estimate / Performa","Raw Material"]
  },
  godown: {
    title:"Godown Report",
    show:["search"],
    searchLabel:"Godown Search",
    searchPlaceholder:"Godown name"
  },
  vehicle: {
    title:"Vehicle Report",
    show:["search","vehicle"],
    searchLabel:"Driver / Owner Search",
    searchPlaceholder:"Driver / owner / phone",
  },
  purchase: {
    title:"Purchase Report",
    show:["date","month","number","search","type"],
    numberLabel:"Purchase No",
    numberPlaceholder:"PUR-0001",
    searchLabel:"Supplier / Product Search",
    searchPlaceholder:"Supplier / product / bill no",
    typeLabel:"Purchase Type",
    typeOptions:()=>["Raw Material Purchase","Finished Goods Purchase"]
  },
  stock: {
    title:"Godown Stock Report",
    show:["godown","product","type"],
    typeLabel:"Stock Type",
    typeOptions:()=>["Positive Stock","Zero Stock"]
  },
  transfer: {
    title:"Stock Transfer Report",
    show:["date","month","number","search","godown","vehicle"],
    numberLabel:"Transfer No",
    numberPlaceholder:"TRF-0001",
    searchLabel:"Product / Driver / Remarks",
    searchPlaceholder:"Product / driver / remarks"
  }
};

function uniqueOptions(arr){
  return [...new Set(arr.filter(Boolean))];
}

function updateReportDropdowns(){
  if(reportGodownFilter){
    const current = reportGodownFilter.value;
    reportGodownFilter.innerHTML = `<option value="">All Godowns</option>` + godowns.map(g=>`<option value="${g.name}">${g.name}</option>`).join("");
    reportGodownFilter.value = current;
  }

  if(reportVehicleFilter){
    const current = reportVehicleFilter.value;
    reportVehicleFilter.innerHTML = `<option value="">All Vehicles</option>` + vehicles.map(v=>`<option value="${v.no}">${v.no} - ${v.name || ""}</option>`).join("");
    reportVehicleFilter.value = current;
  }
}

function setupReportFilters(type){
  const config = reportFilterConfig[type];
  updateReportDropdowns();

  const allBoxes = {
    date:filterDateBox,
    month:filterMonthBox,
    number:filterNumberBox,
    search:filterSearchBox,
    type:filterTypeBox,
    godown:filterGodownBox,
    product:filterProductBox,
    vehicle:filterVehicleBox
  };

  Object.values(allBoxes).forEach(box=>box.style.display = "none");
  config.show.forEach(key=>allBoxes[key].style.display = "block");

  filterSearchLabel.innerText = config.searchLabel || "Search";
  reportSearch.placeholder = config.searchPlaceholder || "Search";

  filterNumberLabel.innerText = config.numberLabel || "Unique Number";
  reportNumber.placeholder = config.numberPlaceholder || "Unique number";

  filterTypeLabel.innerText = config.typeLabel || "Type";
  const typeOptions = config.typeOptions ? config.typeOptions() : [];
  reportTypeFilter.innerHTML = `<option value="">All</option>` + typeOptions.map(v=>`<option value="${v}">${v}</option>`).join("");
}

function getReportFilters(){
  return {
    date: reportDate ? reportDate.value : "",
    month: reportMonth ? reportMonth.value : "",
    number: reportNumber ? reportNumber.value.trim().toLowerCase() : "",
    search: reportSearch ? reportSearch.value.trim().toLowerCase() : "",
    type: reportTypeFilter ? reportTypeFilter.value : "",
    godown: reportGodownFilter ? reportGodownFilter.value : "",
    product: reportProductFilter ? reportProductFilter.value.trim().toLowerCase() : "",
    vehicle: reportVehicleFilter ? reportVehicleFilter.value : ""
  };
}

function matchDateFilters(rowDate, filters){
  if(filters.date && rowDate !== filters.date) return false;
  if(filters.month && !(rowDate || "").startsWith(filters.month)) return false;
  return true;
}

function setReportTable(headers, rows){
  individualReportHead.innerHTML = "<tr>" + headers.map(h=>`<th>${h}</th>`).join("") + "</tr>";
  individualReportBody.innerHTML = rows.length
    ? rows.map(cols=>"<tr>" + cols.map(c=>`<td>${c ?? ""}</td>`).join("") + "</tr>").join("")
    : `<tr><td colspan="${headers.length}" style="text-align:center;color:#64748b;font-weight:800;">No records found</td></tr>`;
}

function setReportSummary(records, qty=0, value=0, typeText=""){
  reportTotalRecords.innerText = records;
  reportTotalQty.innerText = qty;
  reportTotalValue.innerText = rupee(value);
  reportTypeText.innerText = typeText;
}

function openReport(type, btn){
  activeReport = type;

  document.querySelectorAll(".report-tab").forEach(tab=>tab.classList.remove("active"));
  if(btn) btn.classList.add("active");

  const title = reportFilterConfig[type].title;
  activeReportTitle.innerText = title;
  reportTableTitle.innerText = title + " Result";

  clearReportFilters(false);
  setupReportFilters(type);
  renderActiveReport();
}

function clearReportFilters(shouldRender=true){
  reportDate.value = "";
  reportMonth.value = "";
  reportNumber.value = "";
  reportSearch.value = "";
  reportTypeFilter.value = "";
  reportGodownFilter.value = "";
  reportProductFilter.value = "";
  reportVehicleFilter.value = "";
  if(shouldRender) renderActiveReport();
}

function renderActiveReport(){
  if(activeReport === "customer") renderIndividualCustomerReport();
  if(activeReport === "supplier") renderIndividualSupplierReport();
  if(activeReport === "product") renderIndividualProductReport();
  if(activeReport === "godown") renderIndividualGodownReport();
  if(activeReport === "vehicle") renderIndividualVehicleReport();
  if(activeReport === "purchase") renderIndividualPurchaseReport();
  if(activeReport === "stock") renderIndividualStockReport();
  if(activeReport === "transfer") renderIndividualTransferReport();
}

function renderAllReports(){
  setupReportFilters(activeReport);
  renderActiveReport();
}

function renderIndividualCustomerReport(){
  const f = getReportFilters();
  let rows = customers.filter(c=>{
    const text = `${c.name} ${c.mobile || ""} ${c.state || ""} ${c.gstin || ""} ${c.reference || ""}`.toLowerCase();
    const typeOk = !f.type || c.state === f.type;
    return typeOk && (!f.search || text.includes(f.search));
  });

  setReportTable(
    ["Customer", "Mobile", "State", "GSTIN", "Reference", "Pincode"],
    rows.map(c=>[c.name, c.mobile, c.state, c.gstin, c.reference, c.pincode])
  );
  setReportSummary(rows.length, 0, 0, "Customer");
}

function renderIndividualSupplierReport(){
  const f = getReportFilters();
  const list = typeof suppliers !== "undefined" ? suppliers : [];
  let rows = list.filter(s=>{
    const text = `${s.name} ${s.type || ""} ${s.mobile || ""} ${s.gstin || ""} ${s.state || ""}`.toLowerCase();
    const typeOk = !f.type || s.type === f.type;
    return typeOk && (!f.search || text.includes(f.search));
  });

  setReportTable(
    ["Supplier", "Type", "Mobile", "GSTIN", "State", "Pincode"],
    rows.map(s=>[s.name, s.type, s.mobile, s.gstin, s.state, s.pincode])
  );
  setReportSummary(rows.length, 0, 0, "Supplier");
}

function renderIndividualProductReport(){
  const f = getReportFilters();
  const rawList = typeof rawMaterials !== "undefined" ? rawMaterials : [];

  let rows = [
    ...invoiceProducts.map(p=>({...p, list:"Invoice"})),
    ...estimateProducts.map(p=>({...p, list:"Estimate / Performa"})),
    ...rawList.map(p=>({...p, list:"Raw Material"}))
  ].filter(p=>{
    const text = `${p.list} ${p.code} ${p.name} ${p.hsn} ${p.tax} ${p.unit}`.toLowerCase();
    const typeOk = !f.type || p.list === f.type;
    return typeOk && (!f.search || text.includes(f.search));
  });

  setReportTable(
    ["List", "Code", "Product", "HSN", "Tax", "Rate", "Unit Qty", "Unit", "Status"],
    rows.map(p=>[p.list, p.code, p.name, p.hsn, `${p.tax}%`, rupee(p.rate), p.unitQty, p.unit, p.status])
  );
  setReportSummary(rows.length, 0, rows.reduce((sum,p)=>sum+Number(p.rate||0),0), "Product");
}

function renderIndividualGodownReport(){
  const f = getReportFilters();
  let rows = godowns.filter(g=>{
    const text = `${g.name}`.toLowerCase();
    return !f.search || text.includes(f.search);
  });

  setReportTable(["Godown Name"], rows.map(g=>[g.name]));
  setReportSummary(rows.length, 0, 0, "Godown");
}

function renderIndividualVehicleReport(){
  const f = getReportFilters();
  let rows = vehicles.filter(v=>{
    const driverText = (v.drivers || []).map(d=>`${d.name} ${d.phone}`).join(" ");
    const text = `${v.no} ${v.name || ""} ${v.ownerName || ""} ${v.ownerPhone || ""} ${driverText}`.toLowerCase();
    const vehicleOk = !f.vehicle || v.no === f.vehicle;
    return vehicleOk && (!f.search || text.includes(f.search));
  });

  setReportTable(
    ["Vehicle Number", "Vehicle Name", "Owner", "Owner Phone", "Drivers"],
    rows.map(v=>[v.no, v.name, v.ownerName, v.ownerPhone, (v.drivers || []).map(d=>`${d.name} - ${d.phone || ""}`).join("<br>")])
  );
  setReportSummary(rows.length, 0, 0, "Vehicle");
}

function renderIndividualPurchaseReport(){
  const f = getReportFilters();
  let rows = purchases.filter(p=>{
    const text = `${p.no} ${p.supplier} ${p.billNo} ${p.items.map(i=>i.productName).join(" ")}`.toLowerCase();
    const purchaseType = p.type || "";
    return matchDateFilters(p.date, f)
      && (!f.number || (p.no || "").toLowerCase().includes(f.number))
      && (!f.type || purchaseType === f.type)
      && (!f.search || text.includes(f.search));
  });

  const totalQty = rows.reduce((sum,p)=>sum + p.items.reduce((s,i)=>s+Number(i.qty||0),0),0);
  const totalValue = rows.reduce((sum,p)=>sum + p.items.reduce((s,i)=>s+Number(i.amount||0),0),0);

  setReportTable(
    ["Purchase No", "Date", "Supplier", "Bill No", "Items", "Total Qty", "Value"],
    rows.map(p=>{
      const qty = p.items.reduce((sum,i)=>sum+Number(i.qty||0),0);
      const value = p.items.reduce((sum,i)=>sum+Number(i.amount||0),0);
      return [p.no, p.date, p.supplier, p.billNo, p.items.length, qty, rupee(value)];
    })
  );
  setReportSummary(rows.length, totalQty, totalValue, "Purchase");
}

function renderIndividualStockReport(){
  const f = getReportFilters();
  let rows = Object.values(stockLedger).filter(r=>{
    const text = `${r.godownNo} ${r.productCode} ${r.productName} ${r.hsn} ${r.tax} ${r.unit}`.toLowerCase();
    const godownOk = !f.godown || r.godownNo === f.godown;
    const productOk = !f.product || text.includes(f.product);
    const typeOk = !f.type || (f.type === "Positive Stock" ? Number(r.qty) > 0 : Number(r.qty) === 0);
    return godownOk && productOk && typeOk;
  });

  const totalQty = rows.reduce((sum,r)=>sum+Number(r.qty||0),0);
  const totalValue = rows.reduce((sum,r)=>sum+Number(r.value||0),0);

  setReportTable(
    ["Godown", "Product Code", "Product", "HSN", "Tax", "Stock Qty", "Unit", "Avg Rate", "Stock Value"],
    rows.map(r=>[r.godownNo, r.productCode, r.productName, r.hsn, `${r.tax}%`, r.qty, r.unit, rupee(r.avgRate), rupee(r.value)])
  );
  setReportSummary(rows.length, totalQty, totalValue, "Stock");
}

function renderIndividualTransferReport(){
  const f = getReportFilters();
  let rows = transfers.filter(t=>{
    const routeText = t.items.map(i=>`${i.fromGodown} ${i.toGodown} ${i.productName}`).join(" ");
    const text = `${t.no} ${t.vehicleNo} ${t.driverName || ""} ${t.remarks || ""} ${routeText}`.toLowerCase();
    const godownOk = !f.godown || t.items.some(i=>i.fromGodown === f.godown || i.toGodown === f.godown);
    const vehicleOk = !f.vehicle || t.vehicleNo === f.vehicle;
    return matchDateFilters(t.date, f)
      && (!f.number || (t.no || "").toLowerCase().includes(f.number))
      && godownOk
      && vehicleOk
      && (!f.search || text.includes(f.search));
  });

  const totalQty = rows.reduce((sum,t)=>sum + t.items.reduce((s,i)=>s+Number(i.qty||0),0),0);

  setReportTable(
    ["Transfer No", "Date", "Routes", "Vehicle", "Driver", "Items", "Total Qty", "Remarks"],
    rows.map(t=>{
      const qty = t.items.reduce((sum,i)=>sum+Number(i.qty||0),0);
      const routes = [...new Set(t.items.map(i=>`${i.fromGodown} → ${i.toGodown}`))].join("<br>");
      return [t.no, t.date, routes, t.vehicleNo, t.driverName || "", t.items.length, qty, t.remarks || ""];
    })
  );
  setReportSummary(rows.length, totalQty, 0, "Transfer");
}
ERPStorage.loadAll();
invoiceDate.value=new Date().toISOString().split("T")[0];
billState.addEventListener("input",calculateTotal);
billState.addEventListener("change",calculateTotal);
renderCustomers();renderProducts();renderGodowns();renderVehicles();renderVehicleDriverDraft();refreshPurchaseLists();refreshTransferMasters();refreshActiveProductDatalist();setTheme("INV");updateInvoiceNumber();resetRows();if(document.getElementById('additionalChargeRows') && additionalChargeRows.children.length===0){addChargeRow();}
purchaseDate.value = new Date().toISOString().split("T")[0];
transferDate.value = new Date().toISOString().split("T")[0];
updatePurchaseNo();
updateTransferNo();
addPurchaseRow();
addTransferRow();
renderStockTable();
renderTransferHistory();
renderAllReports();

setTimeout(()=>{
  try{
    const rows=document.getElementById('rows');
    if(rows && rows.children.length===0 && typeof addRow==='function'){
      addRow();
    }
  }catch(e){}
},300);


window.addEventListener("DOMContentLoaded", function(){
  setTimeout(function(){
    const rows = document.getElementById("rows");
    if(rows && rows.children.length === 0 && typeof addRow === "function"){
      addRow();
    }
  }, 50);
});


window.addEventListener("load", function(){
  try{
    const rows = document.getElementById("rows");
    if(rows && rows.children.length === 0 && typeof addRow === "function"){
      addRow();
    }
  }catch(err){
    console.error("Product row init failed", err);
  }
});

function ensureDefaultProductRow(){
  try{
    const rows = document.getElementById("rows");
    if(!rows) return;
    if(rows.children.length === 0 && typeof addRow === "function"){
      addRow();
    }
  }catch(err){
    console.error("Default product row failed", err);
  }
}

document.addEventListener("DOMContentLoaded", function(){
  ensureDefaultProductRow();
  setTimeout(ensureDefaultProductRow, 100);
  setTimeout(ensureDefaultProductRow, 500);
});

window.addEventListener("load", function(){
  ensureDefaultProductRow();
  setTimeout(ensureDefaultProductRow, 100);
});


window.addEventListener("load", function(){
  try{
    document.querySelectorAll(".product-row").forEach(row=>{
      if(typeof bindRow === "function") bindRow(row);
      if(typeof calculateRow === "function") calculateRow(row);
    });
    if(typeof updateEstimateColumns === "function") updateEstimateColumns();
    if(typeof calculateTotal === "function") calculateTotal();
  }catch(e){ console.error(e); }
});

window.addEventListener('load', ensureAdditionalChargeRow);
