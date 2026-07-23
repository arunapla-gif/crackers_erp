import React, { useState, useEffect } from 'react';
import { View, Text, TextInput, StyleSheet, SectionList, TouchableOpacity, ActivityIndicator, Alert, Platform, SafeAreaView, Keyboard, Modal, ScrollView, InteractionManager } from 'react-native';
import { erpApi } from '../api/erpApi';
import { useAuth } from '../store/useAuth';
import CustomerDropdown from '../components/CustomerDropdown';

export default function MobileBillingScreen({ navigation }) {
  const { user } = useAuth();
  
  // Data State
  const [products, setProducts] = useState([]);
  const [sections, setSections] = useState([]);
  const [customers, setCustomers] = useState([]);
  const [companyProfiles, setCompanyProfiles] = useState([]);
  const [transporters, setTransporters] = useState([]);
  
  // Billing State
  const [cart, setCart] = useState({});
  const [selectedCustomerId, setSelectedCustomerId] = useState(null);
  const [currentType, setCurrentType] = useState('INV'); // INV, EST, PRO
  
  // Invoice Header State
  const [invoiceHeader, setInvoiceHeader] = useState({
    companyProfileId: null,
    date: new Date().toISOString().split('T')[0],
    transporterId: null,
    vehicleNo: '',
    dispatchAddress: '',
    ewayBillNo: ''
  });

  // Extra Charges State
  const [discountPercent, setDiscountPercent] = useState('');
  const [lorryFreight, setLorryFreight] = useState('');

  // UI State
  const [loading, setLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isKeyboardVisible, setKeyboardVisible] = useState(false);
  
  // Modals
  const [showGateway, setShowGateway] = useState(true);
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [showInvoiceTaxModal, setShowInvoiceTaxModal] = useState(false);
  const [invoiceTaxRef, setInvoiceTaxRef] = useState('');
  const [fetchedInvoiceTax, setFetchedInvoiceTax] = useState(0);

  useEffect(() => {
    const showSubscription = Keyboard.addListener(Platform.OS === 'ios' ? 'keyboardWillShow' : 'keyboardDidShow', () => setKeyboardVisible(true));
    const hideSubscription = Keyboard.addListener(Platform.OS === 'ios' ? 'keyboardWillHide' : 'keyboardDidHide', () => setKeyboardVisible(false));
    return () => { showSubscription.remove(); hideSubscription.remove(); };
  }, []);

  useEffect(() => {
    InteractionManager.runAfterInteractions(() => {
      fetchData();
    });
  }, []);

  // Recalculate grouped sections whenever products or currentType changes
  useEffect(() => {
    if (products.length === 0) return;
    
    const targetType = currentType === 'INV' ? 'INV' : 'EP';
    const filteredProducts = products.filter(p => p.type === targetType);
    
    const grouped = {};
    filteredProducts.forEach(p => {
      const cat = p.subCategory || 'Other';
      if (!grouped[cat]) grouped[cat] = [];
      grouped[cat].push(p);
    });

    const sectionData = Object.keys(grouped).map(cat => ({
      title: cat,
      data: grouped[cat].sort((a, b) => {
        const numA = parseInt(a.name.match(/\d+/)?.[0] || 0);
        const numB = parseInt(b.name.match(/\d+/)?.[0] || 0);
        return numA - numB;
      })
    }));
    sectionData.sort((a, b) => a.title.localeCompare(b.title));
    
    setSections(sectionData);
  }, [products, currentType]);

  const fetchData = async () => {
    try {
      // If we don't have products yet, show the full screen loading spinner
      if (products.length === 0) setLoading(true);

      // Execute all SWR fetches simultaneously
      const [prodRes, custRes, profRes, transRes] = await Promise.all([
        erpApi.getProducts((fresh) => { setProducts(fresh); }),
        erpApi.getCustomers((fresh) => { setCustomers(fresh); }),
        erpApi.getCompanyProfiles((fresh) => { setCompanyProfiles(fresh); }),
        erpApi.getTransporters((fresh) => { setTransporters(fresh); })
      ]);
      
      // Set the initial data (which will be instant if cached)
      setProducts(prodRes.data); 
      setCustomers(custRes.data);
      setCompanyProfiles(profRes.data);
      setTransporters(transRes.data);
    } catch (error) {
      Alert.alert('Error', 'Failed to load master data');
    } finally {
      setLoading(false);
    }
  };

  const updateQuantity = (productId, qtyString) => {
    const qty = parseInt(qtyString) || 0;
    setCart(prev => {
      const newCart = { ...prev };
      if (qty <= 0) delete newCart[productId];
      else newCart[productId] = qty;
      return newCart;
    });
  };

  // Heavy Calculation Logic Mirroring Web App
  const calculateTotals = () => {
    let subtotal = 0;
    Object.keys(cart).forEach(idStr => {
      const id = parseInt(idStr);
      const product = products.find(p => p.id === id);
      if (product) {
        const boxesPerCase = product.boxesPerCase || 1;
        subtotal += (cart[id] * parseFloat(product.rate) * boxesPerCase); 
      }
    });

    let discountAmt = discountPercent ? (subtotal * parseFloat(discountPercent) / 100) : 0;
    let freightAmt = lorryFreight ? parseFloat(lorryFreight) : 0;
    let tax = 0;

    if (currentType === 'INV') {
      tax = subtotal * 0.18; // 18% GST for Invoice
    }

    let grandTotal = subtotal + tax + freightAmt - discountAmt + fetchedInvoiceTax;
    let roundOff = Math.round(grandTotal) - grandTotal;
    
    return { 
      subtotal, 
      tax, 
      discountAmt, 
      freightAmt,
      invoiceTax: fetchedInvoiceTax, 
      roundOff, 
      grandTotal: Math.round(grandTotal) 
    };
  };

  const fetchInvoiceTax = async () => {
    if (!invoiceTaxRef) return Alert.alert('Required', 'Enter Invoice Number');
    try {
      const record = await erpApi.getInvoice(invoiceTaxRef);
      if (record && record.tax) {
        setFetchedInvoiceTax(parseFloat(record.tax));
        Alert.alert('Success', `₹${record.tax} fetched from ${record.number}`);
        setShowInvoiceTaxModal(false);
      }
    } catch (e) {
      Alert.alert('Error', 'Invoice not found.');
    }
  };

  const handleGenerateInvoice = async () => {
    if (!selectedCustomerId) return Alert.alert('Required', 'Please select a customer.');
    if (!invoiceHeader.companyProfileId) return Alert.alert('Required', 'Company Profile required. Reload app.');
    
    Alert.alert(`Generate ${currentType}`, `Proceed to generate?`, [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Proceed', style: 'destructive', onPress: submitInvoice }
    ]);
  };

  const submitInvoice = async () => {
    setIsSubmitting(true);
    const totals = calculateTotals();
    
    const items = Object.keys(cart).map(idStr => {
      const id = parseInt(idStr);
      const p = products.find(prod => prod.id === id);
      const boxes = p?.boxesPerCase || 1;
      const qty = cart[id];
      const rate = parseFloat(p.rate);
      const amount = qty * boxes * rate;
      return {
        productId: id,
        product: p.name,
        qty: qty * boxes,
        rate: rate,
        tax: currentType === 'INV' ? (amount * 0.18) : 0,
        total: amount
      };
    });

    const charges = [];
    if (totals.discountAmt > 0) charges.push({ name: 'Discount', type: 'PERCENT', mode: 'DEDUCT', value: discountPercent, amount: -totals.discountAmt });
    if (totals.freightAmt > 0) charges.push({ name: 'Lorry Freight', type: 'AMOUNT', mode: 'ADD', value: lorryFreight, amount: totals.freightAmt });
    if (fetchedInvoiceTax > 0) charges.push({ name: `Invoice Tax ${invoiceTaxRef}`, source: 'INVOICE_TAX', mode: 'ADD', type: 'AMOUNT', value: fetchedInvoiceTax, amount: fetchedInvoiceTax });

    const payload = {
      series: '', // Backend handles auto-generation if blank
      number: '', 
      date: invoiceHeader.date,
      customer: customers.find(c => c.id === selectedCustomerId)?.name || '',
      vehicleNo: invoiceHeader.vehicleNo,
      transporterId: invoiceHeader.transporterId,
      companyProfileId: invoiceHeader.companyProfileId,
      dispatchAddress: invoiceHeader.dispatchAddress,
      state: 'Tamil Nadu',
      subtotal: totals.subtotal,
      cgst: totals.tax / 2,
      sgst: totals.tax / 2,
      igst: 0,
      tax: totals.tax,
      grand_total: totals.grandTotal,
      items,
      charges,
      type: currentType
    };

    try {
      const res = await erpApi.saveInvoice(payload);
      
      const generateEway = async (mode) => {
        try {
          const ewayRes = await erpApi.generateEwayBill(res.number, mode);
          Alert.alert('E-Way Bill Success', `E-Way Bill No: ${ewayRes.ewayBillNo}`);
        } catch (err) {
          Alert.alert('E-Way Bill Error', 'Failed to generate E-Way Bill via Whitebooks.');
        }
      };

      if (currentType === 'INV') {
        Alert.alert(
          'Success!', 
          `Invoice ${res.number || 'Saved'} generated successfully.`,
          [
            { text: 'Done', style: 'cancel' },
            { 
              text: 'Gen Part A (Transporter)', 
              onPress: () => generateEway('PART_A')
            },
            { 
              text: 'Gen Full (Vehicle)', 
              onPress: () => generateEway('FULL')
            }
          ]
        );
      } else {
        Alert.alert('Success!', `Document ${res.number || 'Saved'} generated successfully.`);
      }

      setCart({});
      setDiscountPercent('');
      setLorryFreight('');
      setFetchedInvoiceTax(0);
      setInvoiceTaxRef('');
    } catch (error) {
      Alert.alert('Error', 'Failed to generate document');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleEwayBill = async () => {
    Alert.alert('E-Way Bill', 'To generate an E-Way Bill, generate the Invoice first. You will be prompted automatically.');
  };

  if (loading) return <View style={styles.center}><ActivityIndicator size="large" color="#4f46e5" /></View>;

  const totals = calculateTotals();

  return (
    <SafeAreaView style={styles.safeArea}>
      
      {/* COMPANY GATEWAY MODAL */}
      <Modal visible={showGateway} animationType="fade">
        <SafeAreaView style={styles.gatewayContainer}>
          <Text style={styles.gatewayTitle}>Select Billing Company</Text>
          {companyProfiles.map(p => (
            <TouchableOpacity 
              key={p.id} 
              style={styles.gatewayCard}
              onPress={() => {
                setInvoiceHeader({...invoiceHeader, companyProfileId: p.id});
                setShowGateway(false);
              }}
            >
              <Text style={styles.gatewayCardText}>{p.name}</Text>
            </TouchableOpacity>
          ))}
        </SafeAreaView>
      </Modal>

      {/* ADVANCED SETTINGS MODAL */}
      <Modal visible={showAdvanced} animationType="slide" presentationStyle="pageSheet">
        <SafeAreaView style={styles.advancedModal}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Advanced Settings</Text>
            <TouchableOpacity onPress={() => setShowAdvanced(false)}>
              <Text style={styles.closeBtn}>Done</Text>
            </TouchableOpacity>
          </View>
          <ScrollView style={{padding: 16}}>
            
            <Text style={styles.inputLabel}>Transporter (Optional)</Text>
            <View style={styles.transporterGrid}>
              {transporters.slice(0, 6).map(t => (
                <TouchableOpacity 
                  key={t.id} 
                  style={[styles.pill, invoiceHeader.transporterId === t.id && styles.pillActive]}
                  onPress={() => setInvoiceHeader({...invoiceHeader, transporterId: t.id})}
                >
                  <Text style={[styles.pillText, invoiceHeader.transporterId === t.id && styles.pillTextActive]}>{t.name}</Text>
                </TouchableOpacity>
              ))}
            </View>

            <Text style={styles.inputLabel}>Vehicle Number</Text>
            <TextInput style={styles.textInput} placeholder="TN 00 AA 0000" value={invoiceHeader.vehicleNo} onChangeText={t => setInvoiceHeader({...invoiceHeader, vehicleNo: t})} />

            <Text style={styles.inputLabel}>Dispatch Address</Text>
            <TextInput style={styles.textInput} placeholder="Address..." value={invoiceHeader.dispatchAddress} onChangeText={t => setInvoiceHeader({...invoiceHeader, dispatchAddress: t})} />

            <TouchableOpacity style={styles.ewayBtn} onPress={handleEwayBill}>
              <Text style={styles.ewayBtnText}>🔥 Generate E-Way Bill (Save First)</Text>
            </TouchableOpacity>
          </ScrollView>
        </SafeAreaView>
      </Modal>

      {/* INVOICE TAX MODAL (For Estimates) */}
      <Modal visible={showInvoiceTaxModal} animationType="fade" transparent={true}>
        <View style={styles.overlay}>
          <View style={styles.taxModalCard}>
            <Text style={styles.inputLabel}>Fetch Invoice Tax</Text>
            <TextInput style={styles.textInput} placeholder="Enter Invoice No" value={invoiceTaxRef} onChangeText={setInvoiceTaxRef} />
            <TouchableOpacity style={styles.fetchBtn} onPress={fetchInvoiceTax}>
              <Text style={styles.fetchBtnText}>Fetch & Add Tax</Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={() => setShowInvoiceTaxModal(false)} style={{marginTop: 16, alignItems: 'center'}}>
              <Text style={{color: '#94a3b8', fontWeight: 'bold'}}>Cancel</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      <View style={styles.container}>
        
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn}><Text style={styles.backBtnText}>←</Text></TouchableOpacity>
          <View style={styles.typeToggle}>
            {['INV', 'EST', 'PRO'].map(t => (
              <TouchableOpacity key={t} style={[styles.typeBtn, currentType === t && styles.typeBtnActive]} onPress={() => {
                setCurrentType(t);
                // Optionally clear cart when switching modes so you don't submit INV products on an EST bill
                if (currentType !== t && Object.keys(cart).length > 0) {
                  Alert.alert('Clear Cart?', 'Switching billing modes will clear your current cart items.', [
                    { text: 'Cancel', onPress: () => setCurrentType(currentType), style: 'cancel' },
                    { text: 'Switch & Clear', onPress: () => setCart({}), style: 'destructive' }
                  ]);
                }
              }}>
                <Text style={[styles.typeBtnText, currentType === t && styles.typeBtnTextActive]}>{t}</Text>
              </TouchableOpacity>
            ))}
          </View>
          <TouchableOpacity onPress={() => setShowAdvanced(true)} style={styles.settingsBtn}><Text>⚙️</Text></TouchableOpacity>
        </View>

        <CustomerDropdown customers={customers} selectedCustomerId={selectedCustomerId} onSelect={setSelectedCustomerId} label="BILL TO" />

        {/* Product Matrix */}
        <SectionList
          style={{ flex: 1 }}
          keyboardShouldPersistTaps="handled"
          keyboardDismissMode="interactive"
          automaticallyAdjustKeyboardInsets={true}
          sections={sections}
          keyExtractor={(item) => item.id.toString()}
          contentContainerStyle={styles.listContent}
          initialNumToRender={15}
          maxToRenderPerBatch={20}
          windowSize={5}
          removeClippedSubviews={true}
          renderSectionHeader={({ section: { title } }) => (
            <View style={styles.sectionHeader}><Text style={styles.sectionHeaderText}>{title.toUpperCase()}</Text></View>
          )}
          renderItem={({ item }) => (
            <View style={styles.productRow}>
              <View style={styles.productInfo}>
                <Text style={styles.productName}>{item.name}</Text>
                <Text style={styles.productRate}>₹{parseFloat(item.rate).toLocaleString()}</Text>
              </View>
              <TextInput
                style={styles.qtyInput}
                placeholder="0" placeholderTextColor="#cbd5e1" keyboardType="number-pad" returnKeyType="done"
                value={cart[item.id] ? cart[item.id].toString() : ''}
                onChangeText={(val) => updateQuantity(item.id, val)}
              />
            </View>
          )}
        />

        {/* Heavy Footer */}
        {!isKeyboardVisible && (
          <View style={styles.footer}>
            <View style={styles.totalsContainer}>
              <View style={styles.totalRow}><Text style={styles.totalLabel}>Subtotal</Text><Text style={styles.totalValue}>₹{totals.subtotal.toLocaleString()}</Text></View>
              
              {currentType === 'INV' && (
                <View style={styles.totalRow}><Text style={styles.totalLabel}>GST (18%)</Text><Text style={styles.totalValue}>+ ₹{totals.tax.toLocaleString()}</Text></View>
              )}

              {/* Extra Charges Inputs */}
              <View style={styles.chargesRow}>
                <View style={{flex: 1, marginRight: 8}}>
                  <Text style={styles.totalLabel}>Discount %</Text>
                  <TextInput style={styles.chargeInput} keyboardType="numeric" placeholder="0" value={discountPercent} onChangeText={setDiscountPercent} />
                </View>
                <View style={{flex: 1}}>
                  <Text style={styles.totalLabel}>Lorry Freight ₹</Text>
                  <TextInput style={styles.chargeInput} keyboardType="numeric" placeholder="0" value={lorryFreight} onChangeText={setLorryFreight} />
                </View>
              </View>

              {totals.discountAmt > 0 && <View style={styles.totalRow}><Text style={styles.totalLabel}>Discount</Text><Text style={styles.totalValueRed}>- ₹{totals.discountAmt.toLocaleString()}</Text></View>}
              
              {(currentType === 'EST' || currentType === 'PRO') && (
                <TouchableOpacity onPress={() => setShowInvoiceTaxModal(true)} style={styles.addTaxBtn}>
                  <Text style={styles.addTaxBtnText}>+ Fetch Invoice Tax</Text>
                </TouchableOpacity>
              )}
              {totals.invoiceTax > 0 && <View style={styles.totalRow}><Text style={styles.totalLabel}>Linked Tax</Text><Text style={styles.totalValue}>+ ₹{totals.invoiceTax.toLocaleString()}</Text></View>}

              <View style={[styles.totalRow, styles.grandTotalRow]}>
                <Text style={styles.grandTotalLabel}>Grand Total</Text>
                <Text style={styles.grandTotalValue}>₹{totals.grandTotal.toLocaleString()}</Text>
              </View>
            </View>
            
            <TouchableOpacity style={[styles.submitBtn, (isSubmitting || Object.keys(cart).length === 0) && styles.submitBtnDisabled]} onPress={handleGenerateInvoice} disabled={isSubmitting || Object.keys(cart).length === 0}>
              {isSubmitting ? <ActivityIndicator color="white" /> : <Text style={styles.submitBtnText}>Generate {currentType}</Text>}
            </TouchableOpacity>
          </View>
        )}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: { flex: 1, backgroundColor: '#f1f5f9' },
  container: { flex: 1 },
  center: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  
  gatewayContainer: { flex: 1, backgroundColor: '#fff', justifyContent: 'center', padding: 24 },
  gatewayTitle: { fontSize: 24, fontWeight: '900', marginBottom: 24, color: '#0f172a', textAlign: 'center' },
  gatewayCard: { backgroundColor: '#f1f5f9', padding: 20, borderRadius: 16, marginBottom: 12, alignItems: 'center' },
  gatewayCardText: { fontSize: 18, fontWeight: 'bold', color: '#4f46e5' },

  header: { padding: 12, backgroundColor: '#fff', flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', borderBottomWidth: 1, borderColor: '#e2e8f0' },
  backBtn: { padding: 8 }, backBtnText: { color: '#4f46e5', fontWeight: 'bold', fontSize: 20 },
  settingsBtn: { padding: 8 },
  
  typeToggle: { flexDirection: 'row', backgroundColor: '#f1f5f9', borderRadius: 8, padding: 4 },
  typeBtn: { paddingHorizontal: 16, paddingVertical: 6, borderRadius: 6 },
  typeBtnActive: { backgroundColor: '#fff', shadowColor: '#000', shadowOffset: {width: 0, height: 1}, shadowOpacity: 0.1, shadowRadius: 2, elevation: 2 },
  typeBtnText: { fontSize: 14, fontWeight: 'bold', color: '#64748b' },
  typeBtnTextActive: { color: '#0f172a' },

  listContent: { padding: 16, paddingBottom: 50 },
  sectionHeader: { backgroundColor: '#f1f5f9', paddingVertical: 8, marginBottom: 8, borderBottomWidth: 2, borderBottomColor: '#10b981' },
  sectionHeaderText: { fontSize: 14, fontWeight: '900', color: '#1e293b', letterSpacing: 1 },
  productRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', backgroundColor: '#fff', padding: 16, borderRadius: 16, marginBottom: 12, shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.05, shadowRadius: 8, elevation: 2 },
  productInfo: { flex: 1, paddingRight: 16 },
  productName: { fontSize: 15, fontWeight: '800', color: '#1e293b', marginBottom: 4 },
  productRate: { fontSize: 13, fontWeight: 'bold', color: '#64748b' },
  qtyInput: { width: 70, height: 50, backgroundColor: '#f8fafc', borderWidth: 1, borderColor: '#cbd5e1', borderRadius: 12, textAlign: 'center', fontSize: 20, fontWeight: '900', color: '#0f172a' },

  footer: { padding: 16, backgroundColor: '#fff', borderTopWidth: 1, borderColor: '#e2e8f0', paddingBottom: Platform.OS === 'ios' ? 30 : 16 },
  totalsContainer: { marginBottom: 16, gap: 4 },
  totalRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginVertical: 2 },
  totalLabel: { fontSize: 13, color: '#64748b', fontWeight: 'bold' },
  totalValue: { fontSize: 14, color: '#475569', fontWeight: 'bold' },
  totalValueRed: { fontSize: 14, color: '#ef4444', fontWeight: 'bold' },
  
  chargesRow: { flexDirection: 'row', marginVertical: 8 },
  chargeInput: { backgroundColor: '#f8fafc', borderWidth: 1, borderColor: '#e2e8f0', borderRadius: 8, padding: 8, marginTop: 4, fontWeight: 'bold' },
  
  addTaxBtn: { alignSelf: 'flex-start', marginVertical: 4 },
  addTaxBtnText: { color: '#4f46e5', fontWeight: 'bold', fontSize: 13 },

  grandTotalRow: { marginTop: 8, paddingTop: 8, borderTopWidth: 1, borderTopColor: '#e2e8f0' },
  grandTotalLabel: { fontSize: 16, color: '#0f172a', fontWeight: '900' },
  grandTotalValue: { fontSize: 24, color: '#10b981', fontWeight: '900' },

  submitBtn: { backgroundColor: '#10b981', padding: 16, borderRadius: 12, alignItems: 'center' },
  submitBtnDisabled: { opacity: 0.5 },
  submitBtnText: { color: '#fff', fontSize: 16, fontWeight: 'bold' },

  // Modals
  advancedModal: { flex: 1, backgroundColor: '#fff' },
  modalHeader: { flexDirection: 'row', justifyContent: 'space-between', padding: 16, borderBottomWidth: 1, borderColor: '#e2e8f0' },
  modalTitle: { fontSize: 18, fontWeight: 'bold' },
  closeBtn: { color: '#4f46e5', fontWeight: 'bold', fontSize: 16 },
  inputLabel: { fontSize: 13, fontWeight: 'bold', color: '#64748b', marginTop: 16, marginBottom: 8 },
  textInput: { backgroundColor: '#f8fafc', borderWidth: 1, borderColor: '#e2e8f0', borderRadius: 12, padding: 12, fontSize: 16, fontWeight: '600' },
  transporterGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  pill: { paddingHorizontal: 12, paddingVertical: 8, backgroundColor: '#f1f5f9', borderRadius: 20 },
  pillActive: { backgroundColor: '#4f46e5' },
  pillText: { fontSize: 13, fontWeight: 'bold', color: '#64748b' },
  pillTextActive: { color: '#fff' },
  ewayBtn: { backgroundColor: '#f59e0b', padding: 16, borderRadius: 12, alignItems: 'center', marginTop: 32 },
  ewayBtnText: { color: '#fff', fontWeight: 'bold', fontSize: 16 },

  overlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'center', padding: 24 },
  taxModalCard: { backgroundColor: '#fff', padding: 24, borderRadius: 16 },
  fetchBtn: { backgroundColor: '#4f46e5', padding: 16, borderRadius: 12, alignItems: 'center', marginTop: 16 },
  fetchBtnText: { color: '#fff', fontWeight: 'bold' }
});
