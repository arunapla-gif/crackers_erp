import { create } from 'zustand';
import AsyncStorage from '@react-native-async-storage/async-storage';

export const useAuth = create((set) => ({
  user: null,
  token: null,
  isLoading: true, // Used for initial load

  init: async () => {
    try {
      const storedUser = await AsyncStorage.getItem('erp_user');
      const storedToken = await AsyncStorage.getItem('erp_token');
      
      if (storedUser && storedToken) {
        set({ user: JSON.parse(storedUser), token: storedToken, isLoading: false });
      } else {
        set({ isLoading: false });
      }
    } catch (e) {
      set({ isLoading: false });
    }
  },

  login: async (user, token) => {
    await AsyncStorage.setItem('erp_user', JSON.stringify(user));
    await AsyncStorage.setItem('erp_token', token);
    set({ user, token });
  },

  logout: async () => {
    await AsyncStorage.removeItem('erp_user');
    await AsyncStorage.removeItem('erp_token');
    set({ user: null, token: null });
  },
}));
