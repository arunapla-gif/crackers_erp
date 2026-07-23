import React, { useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { View, Text, StyleSheet, TouchableOpacity, ActivityIndicator } from 'react-native';
import { useAuth } from './src/store/useAuth';
import LoginScreen from './src/screens/LoginScreen';
import SalesOrderScreen from './src/screens/SalesOrderScreen';
import AdminDashboard from './src/screens/AdminDashboard';
import MobileBillingScreen from './src/screens/MobileBillingScreen';
import PendingOrdersScreen from './src/screens/PendingOrdersScreen';

const Stack = createNativeStackNavigator();
const AdminStackNav = createNativeStackNavigator();

function AdminStack() {
  return (
    <AdminStackNav.Navigator screenOptions={{ headerShown: false }}>
      <AdminStackNav.Screen name="AdminHome" component={AdminDashboard} />
      <AdminStackNav.Screen name="MobileBilling" component={MobileBillingScreen} />
      <AdminStackNav.Screen name="PendingOrders" component={PendingOrdersScreen} />
    </AdminStackNav.Navigator>
  );
}

export default function App() {
  const { user, isLoading, init } = useAuth();

  useEffect(() => {
    init();
  }, []);

  if (isLoading) {
    return (
      <View style={styles.container}>
        <ActivityIndicator size="large" color="#4f46e5" />
      </View>
    );
  }

  return (
    <NavigationContainer>
      <Stack.Navigator screenOptions={{ headerShown: false }}>
        {user ? (
          user.role === 'REP' ? (
            <Stack.Screen name="SalesOrder" component={SalesOrderScreen} />
          ) : (
            <Stack.Screen name="AdminDashboard" component={AdminStack} />
          )
        ) : (
          <Stack.Screen name="Login" component={LoginScreen} />
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fafc',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  text: {
    color: '#0f172a',
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 5,
  },
  subtext: {
    color: '#64748b',
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 30,
  },
  logoutButton: {
    backgroundColor: '#ef4444',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
  },
  logoutButtonText: {
    color: 'white',
    fontWeight: 'bold',
  }
});
