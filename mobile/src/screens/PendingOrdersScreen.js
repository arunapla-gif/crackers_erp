import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity, ActivityIndicator, Alert, SafeAreaView, InteractionManager, RefreshControl } from 'react-native';
import { erpApi } from '../api/erpApi';

export default function PendingOrdersScreen({ navigation }) {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    InteractionManager.runAfterInteractions(() => {
      fetchPendingOrders();
    });
  }, []);

  const fetchPendingOrders = async () => {
    try {
      // If we don't have orders, show the main loading spinner
      if (orders.length === 0) setLoading(true);
      
      const res = await erpApi.getPendingSalesOrders((freshData) => {
        // SWR Callback: When fresh data arrives in background, update silently
        setOrders(freshData);
      });
      
      setOrders(res.data);
    } catch (error) {
      Alert.alert('Error', 'Failed to load pending orders');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const onRefresh = () => {
    setRefreshing(true);
    fetchPendingOrders();
  };

  const handleApprove = (order) => {
    Alert.alert(
      'Approve Order',
      `Are you sure you want to approve the order for ${order.customerName}?`,
      [
        { text: 'Cancel', style: 'cancel' },
        { 
          text: 'Approve', 
          style: 'default',
          onPress: async () => {
            try {
              // Standard web-app logic for approval: approve customer first, then update status
              if (order.status === 'PENDING_CUSTOMER_APPROVAL') {
                await erpApi.approveSalesOrderCustomer(order.id);
              }
              await erpApi.updateSalesOrderStatus(order.id, 'APPROVED');
              Alert.alert('Success', 'Order Approved!');
              fetchPendingOrders();
            } catch (err) {
              Alert.alert('Error', 'Failed to approve order');
            }
          }
        }
      ]
    );
  };

  const handleReject = (order) => {
    Alert.alert(
      'Reject Order',
      `Are you sure you want to reject the order for ${order.customerName}?`,
      [
        { text: 'Cancel', style: 'cancel' },
        { 
          text: 'Reject', 
          style: 'destructive',
          onPress: async () => {
            try {
              await erpApi.updateSalesOrderStatus(order.id, 'REJECTED');
              fetchPendingOrders();
            } catch (err) {
              Alert.alert('Error', 'Failed to reject order');
            }
          }
        }
      ]
    );
  };

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color="#f59e0b" />
        <Text style={{ marginTop: 10, color: '#64748b' }}>Loading Orders...</Text>
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()} style={styles.backBtn}>
          <Text style={styles.backBtnText}>← Back</Text>
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Pending Orders</Text>
        <TouchableOpacity onPress={fetchPendingOrders}>
          <Text style={styles.refreshBtnText}>↻</Text>
        </TouchableOpacity>
      </View>

      <FlatList
        data={orders}
        keyExtractor={(item) => item.id.toString()}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#f59e0b" />
        }
        renderItem={({ item }) => (
          <View style={styles.orderCard}>
            <View style={styles.cardHeader}>
              <View>
                <Text style={styles.customerName}>{item.customerName || item.newCustomerName}</Text>
                <Text style={styles.orderMeta}>
                  {new Date(item.createdAt).toLocaleDateString()} • By {item.rep?.username || 'Unknown Rep'}
                </Text>
              </View>
              <Text style={styles.orderTotal}>₹{parseFloat(item.subtotal).toLocaleString()}</Text>
            </View>

            {item.status === 'PENDING_CUSTOMER_APPROVAL' && (
              <View style={styles.warningBadge}>
                <Text style={styles.warningText}>⚠️ New Customer Requires Approval</Text>
              </View>
            )}

            <View style={styles.actions}>
              <TouchableOpacity style={[styles.btn, styles.rejectBtn]} onPress={() => handleReject(item)}>
                <Text style={styles.rejectBtnText}>Reject</Text>
              </TouchableOpacity>
              <TouchableOpacity style={[styles.btn, styles.approveBtn]} onPress={() => handleApprove(item)}>
                <Text style={styles.approveBtnText}>Approve</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyEmoji}>🎉</Text>
            <Text style={styles.emptyText}>No pending orders right now.</Text>
          </View>
        }
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: { flex: 1, backgroundColor: '#f8fafc' },
  center: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  header: {
    padding: 16,
    backgroundColor: '#fff',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderColor: '#e2e8f0',
  },
  headerTitle: { fontSize: 20, fontWeight: '900', color: '#0f172a' },
  backBtn: { padding: 8, marginLeft: -8 },
  backBtnText: { color: '#f59e0b', fontWeight: 'bold' },
  refreshBtnText: { fontSize: 24, color: '#64748b', fontWeight: 'bold' },
  
  listContent: { padding: 16 },
  orderCard: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 16
  },
  customerName: {
    fontSize: 18,
    fontWeight: '800',
    color: '#1e293b',
    marginBottom: 4
  },
  orderMeta: {
    fontSize: 13,
    fontWeight: '600',
    color: '#94a3b8'
  },
  orderTotal: {
    fontSize: 20,
    fontWeight: '900',
    color: '#10b981'
  },
  warningBadge: {
    backgroundColor: '#fef3c7',
    padding: 8,
    borderRadius: 8,
    marginBottom: 16
  },
  warningText: {
    color: '#d97706',
    fontWeight: 'bold',
    fontSize: 12,
    textAlign: 'center'
  },
  actions: {
    flexDirection: 'row',
    gap: 12
  },
  btn: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: 'center'
  },
  rejectBtn: {
    backgroundColor: '#f1f5f9'
  },
  rejectBtnText: {
    color: '#64748b',
    fontWeight: 'bold'
  },
  approveBtn: {
    backgroundColor: '#f59e0b'
  },
  approveBtnText: {
    color: '#fff',
    fontWeight: 'bold',
    fontSize: 16
  },
  emptyContainer: {
    alignItems: 'center',
    marginTop: 60
  },
  emptyEmoji: {
    fontSize: 60,
    marginBottom: 16
  },
  emptyText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#94a3b8'
  }
});
