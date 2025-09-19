import { useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import { fetchApplications } from '../lib/api'

function normalizeParams(input) {
  if (!input) return {}
  if (typeof input === 'string') {
    return input ? { status: input } : {}
  }
  return input
}

export function useApplications(input) {
  const params = useMemo(() => normalizeParams(input), [input])

  return useQuery({
    queryKey: ['applications', params],
    queryFn: () => fetchApplications(params),
  })
}
