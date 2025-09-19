import { useMemo } from 'react'
import { format, formatDistanceToNow } from 'date-fns'
import {
  CalendarDaysIcon,
  EnvelopeOpenIcon,
  ClipboardDocumentCheckIcon,
} from '@heroicons/react/24/outline'
import { useApplications } from '../hooks/useApplications'
import { useMessages } from '../hooks/useMessages'

function parseDate(value) {
  if (!value) return null
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? null : date
}

function formatDueDate(date) {
  if (!date) return 'Date to be confirmed'
  return format(date, 'EEE, MMM d • p')
}

const TASK_ICON = {
  interview: CalendarDaysIcon,
  invite: EnvelopeOpenIcon,
  assessment: ClipboardDocumentCheckIcon,
}

function asList(possibleList) {
  if (Array.isArray(possibleList)) return possibleList
  if (possibleList && Array.isArray(possibleList.data)) return possibleList.data
  return []
}

export default function DashboardPage() {
  const { data: interviewsRaw, isLoading: loadingInterviews } = useApplications({ status: 'interview_scheduled', limit: 10 })
  const { data: invitesRaw, isLoading: loadingInvites } = useMessages({ classification: 'interview_invite', limit: 10 })
  const { data: assessmentsRaw, isLoading: loadingAssessments } = useMessages({ classification: 'oa', limit: 10 })

  const interviews = asList(interviewsRaw)
  const invites = asList(invitesRaw)
  const assessments = asList(assessmentsRaw)

  const tasks = useMemo(() => {
    const now = new Date()

    const interviewTasks = interviews.map((application) => {
      const dueDate = parseDate(application.interview_at ?? application.last_email_at ?? application.applied_at)
      return {
        id: `interview-${application.id}`,
        type: 'interview',
        label: 'Scheduled interview',
        title: `${application.role_title ?? 'Interview'} @ ${application.company?.name ?? 'Unknown Company'}`,
        dueDate,
        company: application.company?.name,
        role: application.role_title,
        isOverdue: dueDate ? dueDate < now : false,
      }
    })

    const inviteTasks = invites.map((message) => {
      const dueDate = parseDate(message.internal_ts)
      return {
        id: `invite-${message.id}`,
        type: 'invite',
        label: 'Interview invite',
        title: message.subject ?? 'Interview invitation',
        dueDate,
        company: message.application?.company?.name ?? message.application?.role_title,
        role: message.application?.role_title,
        isOverdue: false,
        snippet: message.snippet,
      }
    })

    const assessmentTasks = assessments.map((message) => {
      const dueDate = parseDate(message.internal_ts)
      return {
        id: `assessment-${message.id}`,
        type: 'assessment',
        label: 'Online assessment',
        title: message.subject ?? 'Assessment to complete',
        dueDate,
        company: message.application?.company?.name ?? message.contact?.name,
        role: message.application?.role_title,
        isOverdue: dueDate ? dueDate < now : false,
        snippet: message.snippet,
      }
    })

    return [...interviewTasks, ...inviteTasks, ...assessmentTasks].sort((a, b) => {
      if (!a.dueDate && !b.dueDate) return a.title.localeCompare(b.title)
      if (!a.dueDate) return 1
      if (!b.dueDate) return -1
      return a.dueDate - b.dueDate
    })
  }, [interviews, invites, assessments])

  const stats = useMemo(() => {
    const total = tasks.length
    const overdue = tasks.filter((task) => task.isOverdue).length
    return {
      total,
      overdue,
      interviews: interviews.length,
      invites: invites.length,
      assessments: assessments.length,
    }
  }, [tasks, interviews.length, invites.length, assessments.length])

  const loading = loadingInterviews || loadingInvites || loadingAssessments

  const greeting = useMemo(() => {
    const hour = new Date().getHours()
    if (hour < 12) return 'Good morning'
    if (hour < 18) return 'Good afternoon'
    return 'Good evening'
  }, [])

  const highlightMetrics = [
    { label: 'Scheduled interviews', value: stats.interviews },
    { label: 'Interview invites', value: stats.invites },
    { label: 'Assessments to complete', value: stats.assessments },
  ]

  return (
    <div className="space-y-10">
      <section className="card rounded-3xl border border-base-300/70 bg-base-100/90 shadow-xl">
        <div className="card-body gap-8 md:flex md:items-start md:justify-between">
          <div className="space-y-3 md:max-w-xl">
            <p className="text-xs font-semibold uppercase tracking-[0.3em] text-primary">{greeting}</p>
            <h1 className="text-3xl font-bold leading-tight text-base-content md:text-4xl">
              Stay ahead of every interview and assessment
            </h1>
            <p className="text-sm text-base-content/70">
              CareerPulse brings upcoming interviews, invites, and assessments into a single agenda so you can focus on preparing for what&apos;s next.
            </p>
          </div>
          <div className="stats stats-vertical sm:stats-horizontal bg-base-200/70">
            <div className="stat">
              <div className="stat-title uppercase tracking-wide text-xs text-base-content/60">Pending actions</div>
              <div className="stat-value text-primary">{stats.total}</div>
            </div>
          </div>
        </div>
      </section>

      <section className="grid gap-8 lg:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]">
        <div className="card rounded-3xl border border-base-300/70 bg-base-100/90 shadow-xl">
          <div className="card-body space-y-6">
            <header className="flex flex-wrap items-center justify-between gap-3">
              <div className="space-y-1">
                <h2 className="text-2xl font-semibold text-base-content">Action queue</h2>
                <p className="text-sm text-base-content/70">Prioritized by the date you need to respond or show up.</p>
              </div>
              <span className="badge badge-outline badge-lg font-medium uppercase tracking-wide">
                {tasks.length ? `${tasks.length} items` : 'No actions yet'}
              </span>
            </header>

            {loading ? (
              <div className="flex items-center justify-center py-14">
                <span className="loading loading-lg" aria-label="Loading upcoming tasks" />
              </div>
            ) : tasks.length === 0 ? (
              <div className="rounded-2xl border border-dashed border-base-300/70 bg-base-200/50 py-12 text-center">
                <h3 className="text-lg font-semibold text-base-content">You&apos;re all caught up</h3>
                <p className="mt-2 text-sm text-base-content/70">New invites, assessments, and scheduled interviews will appear here automatically.</p>
              </div>
            ) : (
              <div className="mt-6 space-y-4">
                {tasks.map((task) => {
                  const Icon = TASK_ICON[task.type] ?? CalendarDaysIcon
                  const dueDate = task.dueDate
                  const relative = dueDate ? formatDistanceToNow(dueDate, { addSuffix: true }) : null

                  return (
                    <article
                      key={task.id}
                      className="rounded-2xl border border-base-300/60 bg-base-100/90 p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-lg"
                    >
                      <div className="flex flex-col gap-4 sm:flex-row sm:items-start">
                        <div className="flex h-10 w-10 flex-none items-center justify-center rounded-full bg-primary/10 text-primary">
                          <Icon className="h-5 w-5" />
                        </div>
                        <div className="flex-1 space-y-2">
                          <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                            <div>
                              <p className="text-xs font-semibold uppercase tracking-wide text-primary">{task.label}</p>
                              <h3 className="text-lg font-semibold text-base-content">{task.title}</h3>
                            </div>
                            <div className="text-right">
                              <p className="text-sm font-medium text-base-content/80">{formatDueDate(dueDate)}</p>
                              {relative && <p className="text-xs text-base-content/60">{relative}</p>}
                            </div>
                          </div>
                          {(task.company || task.role) && (
                            <p className="text-sm text-base-content/70">
                              {task.company && <span className="font-medium">{task.company}</span>} {task.company && task.role ? '• ' : ''}
                              {task.role}
                            </p>
                          )}
                          {task.snippet && (
                            <p className="text-sm text-base-content/60">{task.snippet}</p>
                          )}
                        </div>
                      </div>
                    </article>
                  )
                })}
              </div>
            )}
          </div>
        </div>

        <aside className="card rounded-3xl border border-base-300/70 bg-base-100/90 shadow-xl">
          <div className="card-body space-y-5">
            <div className="space-y-1">
              <h2 className="text-xl font-semibold text-base-content">Highlights</h2>
              <p className="text-sm text-base-content/70">Monitor the breakdown of what&apos;s on your radar.</p>
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              {highlightMetrics.map((metric) => (
                <HighlightMetric key={metric.label} {...metric} />
              ))}
            </div>
            <div className="alert alert-info text-sm">
              <span>Keep prep notes and documents handy so you can respond quickly when new actions surface.</span>
            </div>
          </div>
        </aside>
      </section>
    </div>
  )
}

function HighlightMetric({ label, value }) {
  return (
    <div className="rounded-2xl border border-base-200/80 bg-base-100/95 px-4 py-5 shadow-sm">
      <p className="text-xs font-semibold uppercase tracking-wide text-base-content/60">{label}</p>
      <p className="mt-2 text-2xl font-semibold text-base-content">{value}</p>
    </div>
  )
}
