import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { erpApi } from '../api/erpApi';

const numberToWords = (num) => {
  const a = ['', 'One ', 'Two ', 'Three ', 'Four ', 'Five ', 'Six ', 'Seven ', 'Eight ', 'Nine ', 'Ten ', 'Eleven ', 'Twelve ', 'Thirteen ', 'Fourteen ', 'Fifteen ', 'Sixteen ', 'Seventeen ', 'Eighteen ', 'Nineteen '];
  const b = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
  const nString = Math.floor(num).toString();
  if (nString.length > 9) return 'overflow';
  let n = ('000000000' + nString).substr(-9).match(/^(\d{2})(\d{2})(\d{2})(\d{1})(\d{2})$/);
  if (!n) return ''; 
  let str = '';
  str += (n[1] != 0) ? (a[Number(n[1])] || b[n[1][0]] + ' ' + a[n[1][1]]) + 'Crore ' : '';
  str += (n[2] != 0) ? (a[Number(n[2])] || b[n[2][0]] + ' ' + a[n[2][1]]) + 'Lakh ' : '';
  str += (n[3] != 0) ? (a[Number(n[3])] || b[n[3][0]] + ' ' + a[n[3][1]]) + 'Thousand ' : '';
  str += (n[4] != 0) ? (a[Number(n[4])] || b[n[4][0]] + ' ' + a[n[4][1]]) + 'Hundred ' : '';
  str += (n[5] != 0) ? ((str != '') ? 'and ' : '') + (a[Number(n[5])] || b[n[5][0]] + ' ' + a[n[5][1]]) : '';
  return str ? 'Rupees ' + str + 'Only' : '';
};

export default function InvoicePrint({ propNumber, isInline, onPrintComplete }) {
  const { number: routeNumber } = useParams();
  const number = propNumber || routeNumber;
  const [invoice, setInvoice] = useState(null);
  const [customers, setCustomers] = useState([]);

  useEffect(() => {
    erpApi.getInvoice(number).then(setInvoice).catch(console.error);
    erpApi.getCustomers().then(setCustomers).catch(() => {});
  }, [number]);

  useEffect(() => {
    if (invoice) {
      document.title = '\u200b'; // Zero-width space to hide the title in print headers
      setTimeout(() => {
        window.print();
        if (onPrintComplete) {
           setTimeout(onPrintComplete, 500);
        }
      }, 800);
    }
  }, [invoice, onPrintComplete]);

  if (!invoice) return <div className="p-10 font-bold text-center">Loading Invoice...</div>;

  const isEstimate = invoice.number.startsWith('EST');
  const isPerforma = invoice.number.startsWith('PRO');
  const profile = invoice.companyProfile || {};
  const custObj = customers.find(c => c.name === invoice.customer) || {};

  const calculateRate = (taxAmount) => {
    if (!invoice.subtotal || parseFloat(invoice.subtotal) === 0) return '';
    const rate = Math.round((parseFloat(taxAmount) / parseFloat(invoice.subtotal)) * 100);
    return rate > 0 ? ` @ ${rate}%` : '';
  };

  return (
    <div className="bg-white text-black font-sans mx-auto text-[13px] print:overflow-hidden" style={{ width: '210mm', height: '255mm', padding: '8mm', boxSizing: 'border-box' }}>
      <style>
        {`
          @page { margin: 0 !important; }
          @media print {
            body, html { -webkit-print-color-adjust: exact; margin: 0 !important; padding: 0 !important; overflow: hidden !important; height: auto !important; max-height: 100% !important; }
            .print\\:hidden { display: none !important; }
          }
        `}
      </style>

      <div className="mb-4 flex justify-end print:hidden">
        <button onClick={() => window.print()} className="px-6 py-2 bg-slate-800 text-white rounded font-bold shadow hover:bg-slate-900">
          Print Invoice
        </button>
      </div>

      {/* Main Outer Border Box */}
      <div className="border-[1.5px] border-black flex flex-col h-full">
        
        {/* Top Header */}
        <div className="text-center font-bold text-[18px] border-b-[1.5px] border-black py-[2px] uppercase tracking-widest relative">
          {isEstimate ? 'ESTIMATE' : isPerforma ? 'PERFORMA INVOICE' : 'TAX INVOICE'}
          <span className="absolute right-2 top-2 text-[10px] font-bold lowercase tracking-normal">Original for Recipient</span>
        </div>

        {/* Top Section Split: Company vs Invoice Details */}
        <div className="flex border-b-[1.5px] border-black">
          {/* Company Details */}
          <div className="w-[50%] border-r-[1.5px] border-black p-3">
            <h2 className="font-black text-[26px] uppercase mb-1 leading-tight">{profile.name || 'COMPANY NAME'}</h2>
            <p className="font-bold whitespace-pre-wrap leading-[1.4] text-[13px]">{profile.address}</p>
            {profile.city && <p className="font-bold leading-[1.4] text-[13px]">{profile.city}, {profile.state} - {profile.pincode}</p>}
            <p className="mt-1 font-bold text-[13px]">Mobile: {profile.mobile}</p>
            <p className="mt-1 font-bold text-[13px]">GSTIN/UIN: <span className="font-black text-[15px]">{profile.gstin || 'URP'}</span></p>
          </div>
          
          {/* Invoice Details Grid */}
          <div className="w-[50%] flex flex-col">
            <div className="flex border-b-[1.5px] border-black flex-1">
              <div className="w-1/2 border-r-[1.5px] border-black p-2 flex flex-col">
                <span className="text-black text-[11px] font-bold">Invoice No.</span>
                <span className="font-black text-[15px]">{invoice.number}</span>
              </div>
              <div className="w-1/2 p-2 flex flex-col">
                <span className="text-black text-[11px] font-bold">Dated</span>
                <span className="font-black text-[15px]">{new Date(invoice.date).toLocaleDateString('en-IN')}</span>
              </div>
            </div>
            <div className="flex border-b-[1.5px] border-black flex-1">
              <div className="w-1/2 border-r-[1.5px] border-black p-2 flex flex-col">
                <span className="text-black text-[11px] font-bold">State</span>
                <span className="font-bold text-[14px]">{invoice.state || '-'}</span>
              </div>
              <div className="w-1/2 p-2 flex flex-col">
                <span className="text-black text-[11px] font-bold">Transporter</span>
                <span className="font-bold text-[14px]">{invoice.transporterId || '-'}</span>
              </div>
            </div>
            <div className="flex flex-1">
              <div className="w-1/2 border-r-[1.5px] border-black p-2 flex flex-col">
                <span className="text-black text-[11px] font-bold">Vehicle No.</span>
                <span className="font-bold text-[14px]">{invoice.vehicleNo || '-'}</span>
              </div>
              <div className="w-1/2 p-2 flex flex-col">
                <span className="text-black text-[11px] font-bold">E-Way Bill No.</span>
                <span className="font-bold text-[14px]">{invoice.ewayBillNo || '-'}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Billed To */}
        <div className="border-b-[1.5px] border-black p-3 flex">
          <div className="w-full">
            <span className="text-black text-[12px] font-bold block mb-1">Billed To / Consignee:</span>
            <h3 className="font-black text-[18px] uppercase">{invoice.customer}</h3>
            <p className="font-bold whitespace-pre-wrap leading-tight mt-1 text-[14px]">
              {custObj.address || invoice.customerAddress}
              {custObj.city && `, ${custObj.city}`}
              {custObj.district && custObj.district !== custObj.city ? `, ${custObj.district}` : ''}
            </p>
            <p className="mt-[4px] font-bold text-[14px]">
              State: {custObj.state || invoice.state} 
              {custObj.pincode && ` - ${custObj.pincode}`}
            </p>
            {(custObj.mobile || invoice.mobile) && <p className="mt-[2px] font-bold text-[14px]">Mobile: {custObj.mobile || invoice.mobile}</p>}
            <p className="mt-[2px] font-bold text-[14px]">GSTIN/UIN: <span className="font-black text-[15px]">{(invoice.customer && invoice.customer.includes('URP')) ? 'URP' : (custObj.gstin || '')}</span></p>
          </div>
        </div>

        {/* Items Grid with Continuous Vertical Lines */}
        <div className="flex-1 flex flex-col relative">
          
          {/* The visual vertical lines that span the entire height */}
          <div className="absolute top-0 bottom-0 left-[6%] border-l-[1.5px] border-black z-0"></div>
          <div className="absolute top-0 bottom-0 left-[53%] border-l-[1.5px] border-black z-0"></div>
          <div className="absolute top-0 bottom-0 left-[65%] border-l-[1.5px] border-black z-0"></div>
          <div className="absolute top-0 bottom-0 left-[75%] border-l-[1.5px] border-black z-0"></div>
          <div className="absolute top-0 bottom-0 left-[84%] border-l-[1.5px] border-black z-0"></div>
          
          <table className="w-full text-left border-collapse relative z-10 table-fixed">
            <thead>
              <tr className="border-b-[1.5px] border-black">
                <th className="p-2 w-[6%] text-center font-bold text-[12px]">S.No</th>
                <th className="p-2 w-[47%] font-bold text-[12px] pl-2">Description of Goods</th>
                <th className="p-2 w-[12%] text-center font-bold text-[12px]">HSN/SAC</th>
                <th className="p-2 w-[10%] text-center font-bold text-[12px]">Qty</th>
                <th className="p-2 w-[9%] text-center font-bold text-[12px]">Rate</th>
                <th className="p-2 w-[16%] text-right font-bold text-[12px] pr-2">Amount</th>
              </tr>
            </thead>
            <tbody className="text-[13px]">
              {invoice.items && invoice.items.map((item, idx) => (
                <tr key={idx}>
                  <td className="p-2 text-center font-bold align-top">{idx + 1}</td>
                  <td className="p-2 font-bold uppercase align-top pl-2">{item.product}</td>
                  <td className="p-2 text-center font-bold align-top">{item.hsn || '-'}</td>
                  <td className="p-2 font-bold text-center align-top">{item.qty} {item.unit || 'Nos'}</td>
                  <td className="p-2 text-center font-bold align-top">{parseFloat(item.rate).toFixed(2)}</td>
                  <td className="p-2 font-bold text-right align-top pr-2">{parseFloat(item.total).toFixed(2)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Totals Section */}
        <div className="flex border-t-[1.5px] border-black border-b-[1.5px] border-black">
          <div className="w-[65%] border-r-[1.5px] border-black p-3 flex flex-col justify-between">
             <div>
                <span className="text-black text-[12px] font-bold block mb-1">Amount Chargeable (in words)</span>
                <p className="font-bold text-[15px] capitalize leading-snug">INR {numberToWords(invoice.grand_total)}</p>
             </div>
             
             <div className="mt-4">
                <span className="text-black text-[12px] font-bold block mb-1 border-b-[1.5px] border-black inline-block">Company's Bank Details</span>
                <div className="grid grid-cols-[120px_1fr] gap-x-2 text-[12px] mt-1 font-bold">
                  <span>Bank Name</span><span>: {profile.bankName || '-'}</span>
                  <span>A/c No.</span><span>: {profile.accountNumber || '-'}</span>
                  <span>Branch & IFS Code</span><span>: {profile.branch || '-'}  {profile.ifsc ? `(${profile.ifsc})` : ''}</span>
                </div>
             </div>
          </div>
          <div className="w-[35%] flex flex-col text-[13px] font-bold">
            <div className="flex justify-between p-2 border-b-[1.5px] border-black pr-2">
              <span>Subtotal</span>
              <span>₹{parseFloat(invoice.subtotal).toFixed(2)}</span>
            </div>
            {parseFloat(invoice.cgst) > 0 && (
              <div className="flex justify-between p-2 border-b-[1.5px] border-black pr-2">
                <span>Output CGST{calculateRate(invoice.cgst)}</span>
                <span>₹{parseFloat(invoice.cgst).toFixed(2)}</span>
              </div>
            )}
            {parseFloat(invoice.sgst) > 0 && (
              <div className="flex justify-between p-2 border-b-[1.5px] border-black pr-2">
                <span>Output SGST{calculateRate(invoice.sgst)}</span>
                <span>₹{parseFloat(invoice.sgst).toFixed(2)}</span>
              </div>
            )}
            {parseFloat(invoice.igst) > 0 && (
              <div className="flex justify-between p-2 border-b-[1.5px] border-black pr-2">
                <span>Output IGST{calculateRate(invoice.igst)}</span>
                <span>₹{parseFloat(invoice.igst).toFixed(2)}</span>
              </div>
            )}
            {invoice.charges && invoice.charges.length > 0 && invoice.charges.map((charge, idx) => (
              <div key={idx} className="flex justify-between p-2 border-b-[1.5px] border-black pr-2">
                <span>{charge.name || 'Additional Charge'}</span>
                <span>₹{parseFloat(charge.amount).toFixed(2)}</span>
              </div>
            ))}
            <div className="flex justify-between p-2 flex-1 items-center bg-white border-t-[1.5px] border-black pr-2">
              <span className="font-black text-[16px]">Total</span>
              <span className="font-black text-[18px]">₹{parseFloat(invoice.grand_total).toFixed(2)}</span>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="flex min-h-[90px]">
          <div className="w-[65%] border-r-[1.5px] border-black p-3 flex flex-col justify-between">
            <div>
              <span className="text-black text-[12px] font-bold underline block mb-1">Declaration</span>
              <p className="text-[11px] leading-tight w-[90%] font-bold">We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct.</p>
            </div>
            <div className="text-[11px] font-bold mt-2">SUBJECT TO SIVAKASI JURISDICTION</div>
          </div>
          <div className="w-[35%] p-3 flex flex-col items-end justify-between text-right">
            <span className="text-black text-[12px] font-bold">for {profile.name || 'COMPANY NAME'}</span>
            <span className="font-bold text-[12px]">Authorised Signatory</span>
          </div>
        </div>

      </div>
    </div>
  );
}
