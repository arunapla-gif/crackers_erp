import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Modal, TextInput, FlatList, KeyboardAvoidingView, Platform, SafeAreaView, ActivityIndicator, Alert } from 'react-native';
import { erpApi } from '../api/erpApi';

export default function CustomerDropdown({ customers, selectedCustomerId, newCustomerData, onSelect, onNewCustomer, label = "SELECT CUSTOMER" }) {
  const [modalVisible, setModalVisible] = useState(false);
  const [search, setSearch] = useState('');
  
  // New Customer State
  const [isAddingNew, setIsAddingNew] = useState(false);
  const [newCustomerType, setNewCustomerType] = useState('UNREGISTERED');
  const [newGstin, setNewGstin] = useState('');
  const [newName, setNewName] = useState('');
  const [newMobile, setNewMobile] = useState('');
  const [newCity, setNewCity] = useState('');
  const [isVerifying, setIsVerifying] = useState(false);

  const selectedCustomer = customers.find(c => c.id === selectedCustomerId);
  
  const filteredCustomers = customers.filter(c => 
    c.name.toLowerCase().includes(search.toLowerCase())
  );

  const handleFetchGSTIN = async () => {
    if (newGstin.length !== 15) {
      Alert.alert('Invalid', 'Please enter a valid 15-character GSTIN');
      return;
    }
    setIsVerifying(true);
    try {
      const data = await erpApi.verifyGSTIN(newGstin.toUpperCase());
      setNewName(data.tradeName || data.legalName);
      setNewCity(data.city || '');
    } catch (err) {
      Alert.alert('Error', err);
    } finally {
      setIsVerifying(false);
    }
  };

  const handleSaveNewCustomer = () => {
    if (newCustomerType === 'GST' && newGstin.length !== 15) {
      Alert.alert('Required', 'Please fetch a valid GSTIN first');
      return;
    }
    if (!newName) {
      Alert.alert('Required', 'Customer Name is required');
      return;
    }
    
    onNewCustomer({
      type: newCustomerType,
      gstin: newCustomerType === 'GST' ? newGstin.toUpperCase() : '',
      name: newName,
      mobile: newMobile,
      city: newCity
    });
    
    setModalVisible(false);
    setIsAddingNew(false);
  };

  const resetNewForm = () => {
    setNewCustomerType('UNREGISTERED');
    setNewGstin('');
    setNewName('');
    setNewMobile('');
    setNewCity('');
  };

  return (
    <View style={styles.container}>
      <Text style={styles.label}>{label}</Text>
      
      <TouchableOpacity 
        style={styles.dropdownBtn} 
        onPress={() => {
          setIsAddingNew(false);
          setModalVisible(true);
        }}
      >
        <Text style={selectedCustomer || newCustomerData ? styles.selectedText : styles.placeholderText}>
          {newCustomerData 
            ? `${newCustomerData.name} (New Lead)`
            : selectedCustomer 
              ? selectedCustomer.name 
              : 'Tap to search and select...'}
        </Text>
        <Text style={styles.dropdownIcon}>▼</Text>
      </TouchableOpacity>

      <Modal
        visible={modalVisible}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={() => setModalVisible(false)}
      >
        <SafeAreaView style={styles.modalContainer}>
          <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={{flex: 1}}>
            
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>{isAddingNew ? 'Add New Lead' : 'Search Customers'}</Text>
              <TouchableOpacity onPress={() => {
                if (isAddingNew) {
                  setIsAddingNew(false);
                } else {
                  setModalVisible(false);
                }
              }}>
                <Text style={styles.closeBtn}>{isAddingNew ? 'Back' : 'Done'}</Text>
              </TouchableOpacity>
            </View>

            {!isAddingNew ? (
              // =======================================
              // SEARCH EXISTING CUSTOMERS VIEW
              // =======================================
              <>
                <View style={styles.searchContainer}>
                  <TextInput
                    style={styles.searchInput}
                    placeholder="Type to search..."
                    value={search}
                    onChangeText={setSearch}
                    autoFocus
                    clearButtonMode="always"
                  />
                </View>
                
                <TouchableOpacity 
                  style={styles.addNewBtn}
                  onPress={() => {
                    resetNewForm();
                    setIsAddingNew(true);
                  }}
                >
                  <Text style={styles.addNewBtnText}>+ Add New Customer Lead</Text>
                </TouchableOpacity>

                <FlatList
                  data={filteredCustomers}
                  keyExtractor={item => item.id.toString()}
                  keyboardShouldPersistTaps="handled"
                  renderItem={({ item }) => (
                    <TouchableOpacity 
                      style={[styles.customerRow, selectedCustomerId === item.id && styles.customerRowSelected]}
                      onPress={() => {
                        onSelect(item.id);
                        setModalVisible(false);
                        setSearch('');
                      }}
                    >
                      <Text style={[styles.customerName, selectedCustomerId === item.id && styles.customerNameSelected]}>
                        {item.name}
                      </Text>
                      {item.city ? <Text style={styles.customerCity}>{item.city}</Text> : null}
                    </TouchableOpacity>
                  )}
                  ListEmptyComponent={
                    <Text style={styles.emptyText}>No customers found</Text>
                  }
                />
              </>
            ) : (
              // =======================================
              // ADD NEW CUSTOMER VIEW
              // =======================================
              <View style={styles.newCustomerContainer}>
                <View style={styles.toggleContainer}>
                  <TouchableOpacity 
                    style={[styles.toggleBtn, newCustomerType === 'GST' && styles.toggleBtnActive]}
                    onPress={() => setNewCustomerType('GST')}
                  >
                    <Text style={[styles.toggleText, newCustomerType === 'GST' && styles.toggleTextActive]}>GST Registered</Text>
                  </TouchableOpacity>
                  <TouchableOpacity 
                    style={[styles.toggleBtn, newCustomerType === 'UNREGISTERED' && styles.toggleBtnActive]}
                    onPress={() => setNewCustomerType('UNREGISTERED')}
                  >
                    <Text style={[styles.toggleText, newCustomerType === 'UNREGISTERED' && styles.toggleTextActive]}>Unregistered / Cash</Text>
                  </TouchableOpacity>
                </View>

                {newCustomerType === 'GST' && (
                  <View style={styles.inputGroup}>
                    <Text style={styles.inputLabel}>GSTIN (15 Digits) *</Text>
                    <View style={{flexDirection: 'row', gap: 8}}>
                      <TextInput 
                        style={[styles.input, {flex: 1, textTransform: 'uppercase'}]}
                        placeholder="29ABCDE1234F1Z5"
                        value={newGstin}
                        onChangeText={setNewGstin}
                        maxLength={15}
                        autoCapitalize="characters"
                      />
                      <TouchableOpacity 
                        style={[styles.fetchBtn, (isVerifying || newGstin.length !== 15) && styles.fetchBtnDisabled]}
                        onPress={handleFetchGSTIN}
                        disabled={isVerifying || newGstin.length !== 15}
                      >
                        {isVerifying ? <ActivityIndicator color="#fff" size="small" /> : <Text style={styles.fetchBtnText}>Fetch</Text>}
                      </TouchableOpacity>
                    </View>
                  </View>
                )}

                <View style={styles.inputGroup}>
                  <Text style={styles.inputLabel}>Shop / Customer Name *</Text>
                  <TextInput 
                    style={[styles.input, (newCustomerType === 'GST' && newName.length > 0) && styles.inputDisabled]}
                    placeholder="Name"
                    value={newName}
                    onChangeText={setNewName}
                    editable={!(newCustomerType === 'GST' && newName.length > 0)}
                  />
                </View>

                <View style={styles.inputGroup}>
                  <Text style={styles.inputLabel}>Mobile</Text>
                  <TextInput 
                    style={styles.input}
                    placeholder="Mobile Number"
                    keyboardType="phone-pad"
                    value={newMobile}
                    onChangeText={setNewMobile}
                  />
                </View>

                <View style={styles.inputGroup}>
                  <Text style={styles.inputLabel}>City</Text>
                  <TextInput 
                    style={styles.input}
                    placeholder="City"
                    value={newCity}
                    onChangeText={setNewCity}
                  />
                </View>
                
                <View style={{flex: 1}} />

                <TouchableOpacity style={styles.saveBtn} onPress={handleSaveNewCustomer}>
                  <Text style={styles.saveBtnText}>Save & Use Lead</Text>
                </TouchableOpacity>

              </View>
            )}
          </KeyboardAvoidingView>
        </SafeAreaView>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { padding: 16, backgroundColor: '#fff', marginBottom: 8 },
  label: { fontSize: 11, fontWeight: 'bold', color: '#64748b', marginBottom: 8, letterSpacing: 1 },
  dropdownBtn: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#f8fafc', borderWidth: 1, borderColor: '#cbd5e1', borderRadius: 14, paddingHorizontal: 16, paddingVertical: 14 },
  placeholderText: { color: '#94a3b8', fontSize: 15, fontWeight: '600' },
  selectedText: { color: '#0f172a', fontSize: 15, fontWeight: '800' },
  dropdownIcon: { color: '#64748b', fontSize: 12 },
  
  modalContainer: { flex: 1, backgroundColor: '#f8fafc' },
  modalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', padding: 16, backgroundColor: '#fff', borderBottomWidth: 1, borderBottomColor: '#e2e8f0' },
  modalTitle: { fontSize: 18, fontWeight: '900', color: '#0f172a' },
  closeBtn: { fontSize: 16, fontWeight: 'bold', color: '#4f46e5' },
  
  searchContainer: { padding: 16, backgroundColor: '#fff', borderBottomWidth: 1, borderBottomColor: '#e2e8f0' },
  searchInput: { backgroundColor: '#f1f5f9', paddingHorizontal: 16, paddingVertical: 12, borderRadius: 12, fontSize: 16, fontWeight: '600', color: '#0f172a' },
  addNewBtn: { backgroundColor: '#eff6ff', padding: 16, borderBottomWidth: 1, borderBottomColor: '#e2e8f0', alignItems: 'center' },
  addNewBtnText: { color: '#4f46e5', fontWeight: 'bold', fontSize: 15 },
  
  customerRow: { padding: 16, backgroundColor: '#fff', borderBottomWidth: 1, borderBottomColor: '#f1f5f9' },
  customerRowSelected: { backgroundColor: '#eff6ff' },
  customerName: { fontSize: 15, fontWeight: '700', color: '#1e293b', marginBottom: 2 },
  customerNameSelected: { color: '#4f46e5' },
  customerCity: { fontSize: 12, color: '#64748b' },
  emptyText: { textAlign: 'center', marginTop: 40, color: '#94a3b8', fontWeight: 'bold' },
  
  newCustomerContainer: { flex: 1, padding: 16, backgroundColor: '#f8fafc' },
  toggleContainer: { flexDirection: 'row', backgroundColor: '#e2e8f0', borderRadius: 10, padding: 4, marginBottom: 20 },
  toggleBtn: { flex: 1, paddingVertical: 10, alignItems: 'center', borderRadius: 8 },
  toggleBtnActive: { backgroundColor: '#4f46e5', shadowColor: '#000', shadowOffset: {width: 0, height: 1}, shadowOpacity: 0.1, shadowRadius: 2, elevation: 2 },
  toggleText: { fontSize: 13, fontWeight: 'bold', color: '#64748b' },
  toggleTextActive: { color: '#ffffff' },
  
  inputGroup: { marginBottom: 16 },
  inputLabel: { fontSize: 12, fontWeight: '800', color: '#334155', marginBottom: 6 },
  input: { backgroundColor: '#fff', borderWidth: 1, borderColor: '#cbd5e1', borderRadius: 12, paddingHorizontal: 14, height: 48, fontSize: 15, color: '#0f172a' },
  inputDisabled: { backgroundColor: '#f1f5f9', color: '#94a3b8' },
  
  fetchBtn: { backgroundColor: '#4f46e5', borderRadius: 12, justifyContent: 'center', alignItems: 'center', paddingHorizontal: 20 },
  fetchBtnDisabled: { opacity: 0.5 },
  fetchBtnText: { color: '#fff', fontWeight: 'bold', fontSize: 14 },
  
  saveBtn: { backgroundColor: '#10b981', borderRadius: 14, height: 56, justifyContent: 'center', alignItems: 'center', marginBottom: 20 },
  saveBtnText: { color: '#fff', fontSize: 16, fontWeight: '900' }
});
