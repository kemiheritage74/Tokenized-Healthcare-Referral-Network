;; Provider Verification Contract
;; Validates healthcare practitioners and stores their credentials

(define-data-var admin principal tx-sender)

;; Provider status: 0 = unverified, 1 = verified, 2 = suspended
(define-map providers
  { provider-id: principal }
  {
    name: (string-utf8 100),
    license-number: (string-utf8 50),
    status: uint,
    verification-date: uint
  }
)

(define-public (register-provider (name (string-utf8 100)) (license-number (string-utf8 50)))
  (let ((provider-id tx-sender))
    (if (is-none (map-get? providers { provider-id: provider-id }))
        (ok (map-set providers
                     { provider-id: provider-id }
                     {
                       name: name,
                       license-number: license-number,
                       status: u0,
                       verification-date: u0
                     }))
        (err u1) ;; Provider already registered
    )
  )
)

(define-public (verify-provider (provider-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only admin can verify
    (match (map-get? providers { provider-id: provider-id })
      provider-data (ok (map-set providers
                                 { provider-id: provider-id }
                                 (merge provider-data {
                                   status: u1,
                                   verification-date: block-height
                                 })))
      (err u404) ;; Provider not found
    )
  )
)

(define-public (suspend-provider (provider-id principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only admin can suspend
    (match (map-get? providers { provider-id: provider-id })
      provider-data (ok (map-set providers
                                 { provider-id: provider-id }
                                 (merge provider-data { status: u2 })))
      (err u404) ;; Provider not found
    )
  )
)

(define-read-only (get-provider (provider-id principal))
  (map-get? providers { provider-id: provider-id })
)

(define-read-only (is-verified-provider (provider-id principal))
  (match (map-get? providers { provider-id: provider-id })
    provider-data (is-eq (get status provider-data) u1)
    false
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
