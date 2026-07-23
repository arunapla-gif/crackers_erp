import React, { useState, useEffect } from 'react';
import { View, Text, TextInput, StyleSheet, SectionList, TouchableOpacity, ActivityIndicator, Alert, Platform, Keyboard, SafeAreaView, InteractionManager } from 'react-native';
import { erpApi } from '../api/erpApi';
import { useAuth } from '../store/useAuth';
import CustomerDropdown from '../components/CustomerDropdown';

export default function SalesOrderScreen() {
  const { user, logout } = useAuth();
  const [products, setProducts] = useState([]);
  const [sections, setSections] = useState([]);
  const [customers, setCustomers] = useState([]);
  const [loading, setLoading] = useState(true);
  
  // Basic Cart State: { productId: quantity }
  const [cart, setCart] = useState({});
  const [selectedCustomerId, setSelectedCustomerId] = useState(null);
  const [newCustomerData, setNewCustomerData] = useState(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isKeyboardVisible, setKeyboardVisible] = useState(false);

  useEffect(() => {
    const showSubscription = Keyboard.addListener(
      Platform.OS === 'ios' ? 'keyboardWillShow' : 'keyboardDidShow',
      () => setKeyboardVisible(true)
    );
    const hideSubscription = Keyboard.addListener(
      Platform.OS === 'ios' ? 'keyboardWillHide' : 'keyboardDidHide',
      () => setKeyboardVisible(false)
    );

    return () => {
      showSubscription.remove();
      hideSubscription.remove();
    };
  }, []);

  useEffect(() => {
    InteractionManager.runAfterInteractions(() => {
      fetchData();
    });
  }, []);

  // Recalculate grouped sections whenever products change
  useEffect(() => {
    if (products.length === 0) return;
    const grouped = {};
    const epProducts = products.filter(p => p.type === 'EP'); // Sales reps only sell End Products
    epProducts.forEach(p => {
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
  }, [products]);

  const fetchData = async () => {
    try {
      if (products.length === 0) setLoading(true);

      const [prodRes, custRes] = await Promise.all([
        erpApi.getProducts((fresh) => { setProducts(fresh); }),
        erpApi.getCustomers((fresh) => { setCustomers(fresh); })
      ]);
      
      setProducts(prodRes.data); 
      setCustomers(custRes.data);
    } catch (error) {
      Alert.alert('Error', 'Failed to load data');
    } finally {
      setLoading(false);
    }
  };

  const updateQuantity = (productId, qtyString) => {
    const qty = parseInt(qtyString) || 0;
    setCart(prev => {
      const newCart = { ...prev };
      if (qty <= 0) {
        delete newCart[productId];
      } else {
        newCart[productId] = qty;
      }
      return newCart;
    });
  };

  const calculateSubtotal = () => {
    let subtotal = 0;
    Object.keys(cart).forEach(idStr => {
      const id = parseInt(idStr);
      const product = products.find(p => p.id === id);
      if (product) {
        const boxesPerCase = product.boxesPerCase || 1;
        subtotal += (cart[id] * parseFloat(product.rate) * boxesPerCase); 
      }
    });
    return subtotal;
  };

  const handleSubmit = async () => {
    if (!selectedCustomerId && !newCustomerData) {
      Alert.alert('Required', 'Please select a customer or add a new lead.');
      return;
    }
    const cartItems = Object.keys(cart).map(idStr => {
      const id = parseInt(idStr);
      const product = products.find(p => p.id === id);
      return {
        productId: id,
        product: product.name,
        qty: cart[id],
        rate: parseFloat(product.rate)
      };
    });

    if (cartItems.length === 0) {
      Alert.alert('Required', 'Please add at least one item to the order.');
      return;
    }

    const payload = {
      customerId: selectedCustomerId,
      newCustomerData: newCustomerData,
      subtotal: calculateSubtotal(),
      items: cartItems
    };

    setIsSubmitting(true);
    try {
      await erpApi.createSalesOrder(payload);
      Alert.alert('Success', 'Order submitted successfully for approval!', [
        { text: 'OK', onPress: () => {
            setCart({});
            setSelectedCustomerId(null);
            setNewCustomerData(null);
          } 
        }
      ]);
    } catch (error) {
      Alert.alert('Error', 'Failed to submit order. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color="#4f46e5" />
        <Text style={{marginTop: 10, color: '#64748b'}}>Loading Inventory...</Text>
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <View style={styles.container}>
        
        {/* Header */}
        <View style={styles.header}>
          <View>
            <Text style={styles.headerTitle}>New Order</Text>
            <Text style={styles.headerRep}>{user?.name}</Text>
          </View>
          <TouchableOpacity onPress={logout} style={styles.logoutBtn}>
            <Text style={styles.logoutBtnText}>Logout</Text>
          </TouchableOpacity>
        </View>

        {/* Customer Search Dropdown */}
        <CustomerDropdown 
          customers={customers}
          selectedCustomerId={selectedCustomerId}
          newCustomerData={newCustomerData}
          onSelect={(id) => { setSelectedCustomerId(id); setNewCustomerData(null); }}
          onNewCustomer={(data) => { setNewCustomerData(data); setSelectedCustomerId(null); }}
          label="BILL TO CUSTOMER"
        />

        {/* Product Matrix using SectionList */}
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
            <View style={styles.sectionHeader}>
              <Text style={styles.sectionHeaderText}>{title.toUpperCase()}</Text>
            </View>
          )}
          renderItem={({ item }) => (
            <View style={styles.productRow}>
              <View style={styles.productInfo}>
                <Text style={styles.productName}>{item.name}</Text>
                <Text style={styles.productRate}>₹{parseFloat(item.rate).toLocaleString()}</Text>
              </View>
              <TextInput
                style={styles.qtyInput}
                placeholder="0"
                placeholderTextColor="#cbd5e1"
                keyboardType="number-pad"
                value={cart[item.id] ? cart[item.id].toString() : ''}
                onChangeText={(val) => updateQuantity(item.id, val)}
                returnKeyType="done"
              />
            </View>
          )}
        />

        {/* Footer - Hides when keyboard is open to prevent squishing */}
        {!isKeyboardVisible && (
          <View style={styles.footer}>
            <View>
              <Text style={styles.footerLabel}>Subtotal</Text>
              <Text style={styles.footerTotal}>₹{calculateSubtotal().toLocaleString()}</Text>
            </View>
            <TouchableOpacity 
              style={[styles.submitBtn, (isSubmitting || Object.keys(cart).length === 0) && styles.submitBtnDisabled]}
              onPress={handleSubmit}
              disabled={isSubmitting || Object.keys(cart).length === 0}
            >
              {isSubmitting ? (
                <ActivityIndicator color="white" />
              ) : (
                <Text style={styles.submitBtnText}>Submit ({Object.keys(cart).length})</Text>
              )}
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
  
  header: {
    padding: 20,
    backgroundColor: '#fff',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderColor: '#e2e8f0'
  },
  headerTitle: { fontSize: 20, fontWeight: '900', color: '#0f172a' },
  headerRep: { fontSize: 14, fontWeight: 'bold', color: '#4f46e5' },
  logoutBtn: {
    backgroundColor: '#fee2e2',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
  },
  logoutBtnText: { color: '#ef4444', fontWeight: 'bold', fontSize: 12 },

  listContent: { padding: 16, paddingBottom: 100 },
  sectionHeader: {
    backgroundColor: '#f1f5f9',
    paddingVertical: 8,
    marginBottom: 8,
    borderBottomWidth: 2,
    borderBottomColor: '#4f46e5'
  },
  sectionHeaderText: {
    fontSize: 14,
    fontWeight: '900',
    color: '#1e293b',
    letterSpacing: 1
  },
  productRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 16,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2
  },
  productInfo: { flex: 1, paddingRight: 16 },
  productName: { fontSize: 15, fontWeight: '800', color: '#1e293b', marginBottom: 4 },
  productRate: { fontSize: 13, fontWeight: 'bold', color: '#64748b' },
  qtyInput: {
    width: 70,
    height: 50,
    backgroundColor: '#f8fafc',
    borderWidth: 1,
    borderColor: '#cbd5e1',
    borderRadius: 12,
    textAlign: 'center',
    fontSize: 20,
    fontWeight: '900',
    color: '#0f172a'
  },

  footer: {
    padding: 20,
    backgroundColor: '#0f172a',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingBottom: Platform.OS === 'ios' ? 40 : 20,
  },
  footerLabel: { fontSize: 12, fontWeight: 'bold', color: '#94a3b8', textTransform: 'uppercase' },
  footerTotal: { fontSize: 24, fontWeight: '900', color: '#fff' },
  submitBtn: {
    backgroundColor: '#4f46e5',
    paddingHorizontal: 24,
    paddingVertical: 14,
    borderRadius: 12,
  },
  submitBtnDisabled: { opacity: 0.5 },
  submitBtnText: { color: '#fff', fontSize: 16, fontWeight: 'bold' }
});
