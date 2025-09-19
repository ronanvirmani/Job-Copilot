import axios from 'axios'
import { supabase } from './supabase'

const API_BASE_URL = import.meta.env.VITE_API_URL

if (!API_BASE_URL) {
  // eslint-disable-next-line no-console
  console.warn('VITE_API_URL is not defined; API requests will fail until set')
}

export function withAuth(config) {
  return supabase.auth.getSession().then(({ data }) => {
    const session = data.session ?? null

    if (session?.access_token) {
      config.headers = {
        ...config.headers,
        Authorization: `Bearer ${session.access_token}`,
      }
    }

    return config
  })
}

export const api = axios.create({
  baseURL: API_BASE_URL,
})

api.interceptors.request.use(withAuth)

export async function fetchApplications(params = {}) {
  const response = await api.get('/applications', { params })
  return response.data
}

export async function fetchMessages(params = {}) {
  const response = await api.get('/messages', { params })
  return response.data
}

export default api
