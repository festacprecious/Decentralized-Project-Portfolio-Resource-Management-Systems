;; Performance Tracking Contract
;; Tracks portfolio and project performance metrics

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_INPUT (err u400))
(define-constant ERR_ALREADY_EXISTS (err u409))

;; Data Variables
(define-data-var contract-paused bool false)
(define-data-var milestone-counter uint u0)
(define-data-var performance-record-counter uint u0)

;; Data Maps
(define-map project-performance
  { project-id: (string-ascii 50) }
  {
    total-milestones: uint,
    completed-milestones: uint,
    completion-rate: uint,
    last-updated: uint,
    performance-score: uint,
    status: (string-ascii 20)
  }
)

(define-map milestones
  { milestone-id: uint }
  {
    project-id: (string-ascii 50),
    milestone-name: (string-ascii 100),
    target-block: uint,
    completed-block: uint,
    completion-status: (string-ascii 20),
    performance-impact: uint,
    created-by: principal
  }
)

(define-map performance-records
  { record-id: uint }
  {
    project-id: (string-ascii 50),
    metric-type: (string-ascii 30),
    metric-value: uint,
    recorded-block: uint,
    recorded-by: principal,
    notes: (string-ascii 200)
  }
)

(define-map portfolio-performance
  { portfolio-id: (string-ascii 50) }
  {
    total-projects: uint,
    active-projects: uint,
    completed-projects: uint,
    overall-performance: uint,
    last-calculated: uint
  }
)

;; Public Functions

;; Initialize project performance tracking
(define-public (initialize-project-performance (project-id (string-ascii 50)))
  (begin
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
    (asserts! (> (len project-id) u0) ERR_INVALID_INPUT)
    (asserts! (is-none (map-get? project-performance { project-id: project-id })) ERR_ALREADY_EXISTS)

    (map-set project-performance
      { project-id: project-id }
      {
        total-milestones: u0,
        completed-milestones: u0,
        completion-rate: u0,
        last-updated: block-height,
        performance-score: u0,
        status: "active"
      }
    )
    (ok true)
  )
)

;; Add milestone to project
(define-public (add-milestone (project-id (string-ascii 50)) (milestone-name (string-ascii 100)) (target-block uint) (performance-impact uint))
  (let
    (
      (milestone-id (+ (var-get milestone-counter) u1))
      (project-perf (unwrap! (map-get? project-performance { project-id: project-id }) ERR_NOT_FOUND))
    )
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
    (asserts! (> (len milestone-name) u0) ERR_INVALID_INPUT)
    (asserts! (> target-block block-height) ERR_INVALID_INPUT)

    ;; Create milestone
    (map-set milestones
      { milestone-id: milestone-id }
      {
        project-id: project-id,
        milestone-name: milestone-name,
        target-block: target-block,
        completed-block: u0,
        completion-status: "pending",
        performance-impact: performance-impact,
        created-by: tx-sender
      }
    )

    ;; Update project performance
    (map-set project-performance
      { project-id: project-id }
      (merge project-perf {
        total-milestones: (+ (get total-milestones project-perf) u1),
        last-updated: block-height
      })
    )

    (var-set milestone-counter milestone-id)
    (ok milestone-id)
  )
)

;; Complete milestone
(define-public (complete-milestone (milestone-id uint))
  (let
    (
      (milestone-data (unwrap! (map-get? milestones { milestone-id: milestone-id }) ERR_NOT_FOUND))
      (project-id (get project-id milestone-data))
      (project-perf (unwrap! (map-get? project-performance { project-id: project-id }) ERR_NOT_FOUND))
      (new-completed (+ (get completed-milestones project-perf) u1))
      (new-completion-rate (/ (* new-completed u100) (get total-milestones project-perf)))
    )
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get completion-status milestone-data) "pending") ERR_INVALID_INPUT)

    ;; Update milestone
    (map-set milestones
      { milestone-id: milestone-id }
      (merge milestone-data {
        completed-block: block-height,
        completion-status: "completed"
      })
    )

    ;; Update project performance
    (map-set project-performance
      { project-id: project-id }
      (merge project-perf {
        completed-milestones: new-completed,
        completion-rate: new-completion-rate,
        last-updated: block-height,
        performance-score: (calculate-performance-score new-completion-rate (get performance-impact milestone-data))
      })
    )

    (ok true)
  )
)

;; Record performance metric
(define-public (record-performance-metric (project-id (string-ascii 50)) (metric-type (string-ascii 30)) (metric-value uint) (notes (string-ascii 200)))
  (let
    (
      (record-id (+ (var-get performance-record-counter) u1))
    )
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
    (asserts! (> (len project-id) u0) ERR_INVALID_INPUT)
    (asserts! (> (len metric-type) u0) ERR_INVALID_INPUT)

    (map-set performance-records
      { record-id: record-id }
      {
        project-id: project-id,
        metric-type: metric-type,
        metric-value: metric-value,
        recorded-block: block-height,
        recorded-by: tx-sender,
        notes: notes
      }
    )

    (var-set performance-record-counter record-id)
    (ok record-id)
  )
)

;; Update project status
(define-public (update-project-status (project-id (string-ascii 50)) (new-status (string-ascii 20)))
  (let
    (
      (project-perf (unwrap! (map-get? project-performance { project-id: project-id }) ERR_NOT_FOUND))
    )
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
    (asserts! (or (is-eq tx-sender CONTRACT_OWNER) (is-eq tx-sender tx-sender)) ERR_UNAUTHORIZED)

    (map-set project-performance
      { project-id: project-id }
      (merge project-perf {
        status: new-status,
        last-updated: block-height
      })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get project performance
(define-read-only (get-project-performance (project-id (string-ascii 50)))
  (map-get? project-performance { project-id: project-id })
)

;; Get milestone information
(define-read-only (get-milestone (milestone-id uint))
  (map-get? milestones { milestone-id: milestone-id })
)

;; Get performance record
(define-read-only (get-performance-record (record-id uint))
  (map-get? performance-records { record-id: record-id })
)

;; Get portfolio performance
(define-read-only (get-portfolio-performance (portfolio-id (string-ascii 50)))
  (map-get? portfolio-performance { portfolio-id: portfolio-id })
)

;; Get milestone count
(define-read-only (get-milestone-count)
  (var-get milestone-counter)
)

;; Get performance record count
(define-read-only (get-performance-record-count)
  (var-get performance-record-counter)
)

;; Check if project is performing well (>= 75% completion rate)
(define-read-only (is-performing-well (project-id (string-ascii 50)))
  (match (map-get? project-performance { project-id: project-id })
    perf-data (>= (get completion-rate perf-data) u75)
    false
  )
)

;; Private Functions

;; Calculate performance score based on completion rate and impact
(define-private (calculate-performance-score (completion-rate uint) (impact uint))
  (let
    (
      (base-score completion-rate)
      (impact-bonus (/ (* impact u10) u100))
    )
    (+ base-score impact-bonus)
  )
)

;; Admin Functions

;; Pause contract
(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set contract-paused true)
    (ok true)
  )
)

;; Unpause contract
(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set contract-paused false)
    (ok true)
  )
)
