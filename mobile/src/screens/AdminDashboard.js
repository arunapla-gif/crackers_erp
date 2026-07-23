import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, SafeAreaView, ScrollView } from 'react-native';
import { useAuth } from '../store/useAuth';

export default function AdminDashboard({ navigation }) {
  const { user, logout } = useAuth();

  return (
    <SafeAreaView style={styles.safeArea}>
      <ScrollView style={styles.container} contentContainerStyle={{ padding: 24 }}>
        
        {/* Header */}
        <View style={styles.header}>
          <View>
            <Text style={styles.welcomeText}>Welcome back,</Text>
            <Text style={styles.nameText}>{user?.name || 'Admin'} 👋</Text>
          </View>
          <TouchableOpacity style={styles.logoutBtn} onPress={logout}>
            <Text style={styles.logoutBtnText}>Logout</Text>
          </TouchableOpacity>
        </View>

        <Text style={styles.sectionTitle}>Quick Actions</Text>

        {/* Action Grid */}
        <View style={styles.grid}>
          <TouchableOpacity 
            style={[styles.card, styles.billingCard]}
            onPress={() => navigation.navigate('MobileBilling')}
          >
            <Text style={styles.cardEmoji}>🧾</Text>
            <Text style={styles.cardTitle}>Mobile Billing</Text>
            <Text style={styles.cardSub}>Create Live GST Bills</Text>
          </TouchableOpacity>

          <TouchableOpacity 
            style={[styles.card, styles.ordersCard]}
            onPress={() => navigation.navigate('PendingOrders')}
          >
            <Text style={styles.cardEmoji}>🔔</Text>
            <Text style={styles.cardTitle}>Pending Orders</Text>
            <Text style={styles.cardSub}>Approve Rep Orders</Text>
          </TouchableOpacity>
        </View>

      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: { flex: 1, backgroundColor: '#f8fafc' },
  container: { flex: 1 },
  
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 40,
    marginTop: 20,
  },
  welcomeText: { fontSize: 16, color: '#64748b', fontWeight: 'bold' },
  nameText: { fontSize: 28, fontWeight: '900', color: '#0f172a', letterSpacing: -0.5 },
  
  logoutBtn: {
    backgroundColor: '#fee2e2',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
  },
  logoutBtnText: { color: '#ef4444', fontWeight: 'bold', fontSize: 12 },

  sectionTitle: {
    fontSize: 14,
    fontWeight: '900',
    color: '#94a3b8',
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: 16,
  },
  
  grid: {
    gap: 16,
  },
  card: {
    padding: 24,
    borderRadius: 24,
    height: 160,
    justifyContent: 'flex-end',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.1,
    shadowRadius: 20,
    elevation: 5,
  },
  billingCard: {
    backgroundColor: '#4f46e5',
  },
  ordersCard: {
    backgroundColor: '#f59e0b',
  },
  cardEmoji: {
    position: 'absolute',
    top: 20,
    right: 20,
    fontSize: 40,
    opacity: 0.8,
  },
  cardTitle: {
    fontSize: 24,
    fontWeight: '900',
    color: '#fff',
    marginBottom: 4,
  },
  cardSub: {
    fontSize: 14,
    fontWeight: '600',
    color: 'rgba(255,255,255,0.8)',
  }
});
