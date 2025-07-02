;; Optimization Planning Contract
;; Plans and executes portfolio optimization strategies

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_INPUT (err u400))
(define-constant ERR_ALREADY_EXISTS (err u409))

;; Data Variables
(define-data-var contract-paused bool false)
(define-data-var optimization-counter uint u0)
(define-data-var recommendation-counter uint u0)

;; Data Maps
(define-map optimization-plans
  { plan-id: uint }
  {
    portfolio-id: (string-ascii 50),
    plan-name: (string-ascii 100),
    optimization-type: (string-ascii 30),
    target-improvement: uint,
    created-by: principal,
    created-block: uint,
    status: (string-ascii 20),
    implementation-deadline: uint
  }
)

(define-map optimization-recommendations
  { recommendation-id: uint }
  {
    plan-id: uint,
    recommendation-type: (string-ascii 30),
    description: (string-ascii 200),
    priority-level: uint,
    estimated-impact: uint,
    implementation-cost: uint,
    created-block: uint
  }
)

(define-map resource-efficiency
  { portfolio-id: (string-ascii 50) }
  {
    total-resources: uint,
    utilized-resources: uint,
    efficiency-score: uint,
    last-calculated: uint,
    optimization-potential: uint
  }
)

(define-map optimization-results
  { plan-id: uint }
  {
    implementation-date: uint,
    actual-improvement: uint,
    cost-effectiveness: uint,
    success-rate: uint,
    lessons-learned: (string-ascii 300)
  }
)

;; Public Functions

;; Create optimization plan
(define-public (create-optimization-plan
  (portfolio-id (string-ascii 50))
  (plan-name (string-ascii 100))
  (optimization-type (string-ascii 30))
  (target-improvement uint)
  (implementation-deadline uint))
  (let
    (
      (plan-id (+ (var-get optimization-counter) u1))
    )
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
    (asserts! (> (len plan-name) u0) ERR_INVALID_INPUT)
    (asserts! (> target-improvement u0) ERR_INVALID_INPUT)
    (asserts! (> implementation-deadline block-height) ERR_INVALID_INPUT)

    (map-set optimization-plans
      { plan-id: plan-id }
      {
        portfolio-id: portfolio-id,
        plan-name: plan-name,
        optimization-type: optimization-type,
        target-improvement: target-improvement,
        created-by: tx-sender,
        created-block: block-height,
        status: "draft",
        implementation-deadline: implementation-deadline
      }
    )

    (var-set optimization-counter plan-id)
    (ok plan-id)
  )
)

;; Add optimization recommendation
(define-public (add-recommendation
  (plan-id uint)
  (recommendation-type (string-ascii 30))
  (description (string-ascii 200))
  (priority-level uint)
  (estimated-impact uint)
  (implementation-cost uint))
  (let
    (
      (recommendation-id (+ (var-get recommendation-counter) u1))
      (plan-data (unwrap! (map-get? optimization-plans { plan-id: plan-id }) ERR_NOT_FOUND))
    )
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
    (asserts! (> (len description) u0) ERR_INVALID_INPUT)
    (asserts! (and (>= priority-level u1) (<= priority-level u5)) ERR_INVALID_INPUT)

    (map-set optimization-recommendations
      { recommendation-id: recommendation-id }
      {
        plan-id: plan-id,
        recommendation-type: recommendation-type,
        description: description,
        priority-level: priority-level,
        estimated-impact: estimated-impact,
        implementation-cost: implementation-cost,
        created-block: block-height
      }
    )

    (var-set recommendation-counter recommendation-id)
    (ok recommendation-id)
  )
)

;; Calculate resource efficiency
(define-public (calculate-resource-efficiency (portfolio-id (string-ascii 50)) (total-resources uint) (utilized-resources uint))
  (let
    (
      (efficiency-score (if (> total-resources u0) (/ (* utilized-resources u100) total-resources) u0))
      (optimization-potential (- u100 efficiency-score))
    )
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
    (asserts! (>= total-resources utilized-resources) ERR_INVALID_INPUT)

    (map-set resource-efficiency
      { portfolio-id: portfolio-id }
      {
        total-resources: total-resources,
        utilized-resources: utilized-resources,
        efficiency-score: efficiency-score,
        last-calculated: block-height,
        optimization-potential: optimization-potential
      }
    )
    (ok efficiency-score)
  )
)

;; Approve optimization plan
(define-public (approve-optimization-plan (plan-id uint))
  (let
    (
      (plan-data (unwrap! (map-get? optimization-plans { plan-id: plan-id }) ERR_NOT_FOUND))
    )
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
    (asserts! (or (is-eq tx-sender CONTRACT_OWNER) (is-eq tx-sender (get created-by plan-data))) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status plan-data) "draft") ERR_INVALID_INPUT)

    (map-set optimization-plans
      { plan-id: plan-id }
      (merge plan-data { status: "approved" })
    )
    (ok true)
  )
)

;; Implement optimization plan
(define-public (implement-optimization-plan (plan-id uint))
  (let
    (
      (plan-data (unwrap! (map-get? optimization-plans { plan-id: plan-id }) ERR_NOT_FOUND))
    )
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status plan-data) "approved") ERR_INVALID_INPUT)

    (map-set optimization-plans
      { plan-id: plan-id }
      (merge plan-data { status: "implementing" })
    )
    (ok true)
  )
)

;; Record optimization results
(define-public (record-optimization-results
  (plan-id uint)
  (actual-improvement uint)
  (cost-effectiveness uint)
  (success-rate uint)
  (lessons-learned (string-ascii 300)))
  (let
    (
      (plan-data (unwrap! (map-get? optimization-plans { plan-id: plan-id }) ERR_NOT_FOUND))
    )
    (asserts! (not (var-get contract-paused)) ERR_UNAUTHORIZED)
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status plan-data) "implementing") ERR_INVALID_INPUT)

    (map-set optimization-results
      { plan-id: plan-id }
      {
        implementation-date: block-height,
        actual-improvement: actual-improvement,
        cost-effectiveness: cost-effectiveness,
        success-rate: success-rate,
        lessons-learned: lessons-learned
      }
    )

    (map-set optimization-plans
      { plan-id: plan-id }
      (merge plan-data { status: "completed" })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get optimization plan
(define-read-only (get-optimization-plan (plan-id uint))
  (map-get? optimization-plans { plan-id: plan-id })
)

;; Get optimization recommendation
(define-read-only (get-recommendation (recommendation-id uint))
  (map-get? optimization-recommendations { recommendation-id: recommendation-id })
)

;; Get resource efficiency
(define-read-only (get-resource-efficiency (portfolio-id (string-ascii 50)))
  (map-get? resource-efficiency { portfolio-id: portfolio-id })
)

;; Get optimization results
(define-read-only (get-optimization-results (plan-id uint))
  (map-get? optimization-results { plan-id: plan-id })
)

;; Get optimization count
(define-read-only (get-optimization-count)
  (var-get optimization-counter)
)

;; Get recommendation count
(define-read-only (get-recommendation-count)
  (var-get recommendation-counter)
)

;; Check if portfolio needs optimization (efficiency < 70%)
(define-read-only (needs-optimization (portfolio-id (string-ascii 50)))
  (match (map-get? resource-efficiency { portfolio-id: portfolio-id })
    efficiency-data (< (get efficiency-score efficiency-data) u70)
    true
  )
)

;; Get optimization priority level
(define-read-only (get-optimization-priority (portfolio-id (string-ascii 50)))
  (match (map-get? resource-efficiency { portfolio-id: portfolio-id })
    efficiency-data
      (let ((score (get efficiency-score efficiency-data)))
        (if (< score u50) "critical"
          (if (< score u70) "high"
            (if (< score u85) "medium" "low"))))
    "unknown"
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
