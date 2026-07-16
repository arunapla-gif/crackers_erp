import { create } from 'zustand';

// Simple persistence
const loadUser = () => {
  try {
    const user = localStorage.getItem('erp_user');
    return user ? JSON.parse(user) : null;
  } catch {
    return null;
  }
};

const loadToken = () => {
  try {
    return localStorage.getItem('erp_token') || null;
  } catch {
    return null;
  }
};

export const useAuth = create((set) => ({
  user: loadUser(),
  token: loadToken(),
  
  login: (userData, token) => {
    localStorage.setItem('erp_user', JSON.stringify(userData));
    localStorage.setItem('erp_token', token);
    set({ user: userData, token });
  },
  
  logout: () => {
    localStorage.removeItem('erp_user');
    localStorage.removeItem('erp_token');
    set({ user: null, token: null });
  }
}));
