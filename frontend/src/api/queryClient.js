import { QueryClient } from '@tanstack/react-query';

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      // Data is considered fresh for 10 minutes
      staleTime: 10 * 60 * 1000, 
      // Keep data in cache for 30 minutes
      gcTime: 30 * 60 * 1000,
      // Refetch on window focus only if stale
      refetchOnWindowFocus: true,
      // Retry failed queries 1 time
      retry: 1,
    },
  },
});
