import { useQuery, useMutation } from '@tanstack/react-query';
import { erpApi } from './erpApi';
import { queryClient } from './queryClient';

// --- QUERIES ---

export const useProducts = () => {
  return useQuery({
    queryKey: ['products'],
    queryFn: erpApi.getProducts,
  });
};

export const useCustomers = () => {
  return useQuery({
    queryKey: ['customers'],
    queryFn: async () => {
      const data = await erpApi.getCustomers();
      return data.filter(c => c.status !== 'Inactive');
    },
  });
};

export const useTransporters = () => {
  return useQuery({
    queryKey: ['transporters'],
    queryFn: async () => {
      const data = await erpApi.getTransporters();
      return data.filter(t => t.status !== 'Inactive');
    },
  });
};

export const useCompanyProfiles = () => {
  return useQuery({
    queryKey: ['companyProfiles'],
    queryFn: async () => {
      const data = await erpApi.getCompanyProfiles();
      return data.filter(p => p.status !== 'Inactive');
    },
  });
};

// --- MUTATIONS (Optimistic UI) ---

export const useSaveInvoice = () => {
  return useMutation({
    mutationFn: erpApi.createInvoice,
    onMutate: async (newInvoice) => {
      // Cancel any outgoing refetches so they don't overwrite our optimistic update
      await queryClient.cancelQueries({ queryKey: ['invoices'] });

      // Snapshot the previous value
      const previousInvoices = queryClient.getQueryData(['invoices']);

      // Optimistically update to the new value
      queryClient.setQueryData(['invoices'], (old) => {
        return old ? [newInvoice, ...old] : [newInvoice];
      });

      // Return a context object with the snapshotted value
      return { previousInvoices };
    },
    // If the mutation fails, use the context returned from onMutate to roll back
    onError: (err, newInvoice, context) => {
      queryClient.setQueryData(['invoices'], context.previousInvoices);
    },
    // Always refetch after error or success:
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['invoices'] });
    },
  });
};
