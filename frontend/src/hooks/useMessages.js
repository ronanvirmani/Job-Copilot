import { useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import { fetchMessages } from '../lib/api'

function normalizeParams(input) {
  if (!input) return {}
  if (typeof input === 'string') {
    return input ? { classification: input } : {}
  }
  return input
}

export function useMessages(input) {
  const params = useMemo(() => normalizeParams(input), [input])

  return useQuery({
    queryKey: ['messages', params],
    queryFn: () => fetchMessages(params),
  })
}
