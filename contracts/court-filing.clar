;; Digital Court Filing System Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data Variables
(define-map filings
    { case-id: uint }
    {
        plaintiff: principal,
        defendant: principal,
        judge: principal,
        status: (string-ascii 20),
        timestamp: uint,
        document-hash: (buff 32)
    }
)

(define-map authorized-judges principal bool)

;; Filing counter
(define-data-var filing-count uint u0)

;; Authorization functions
(define-public (add-judge (judge-address principal))
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-set authorized-judges judge-address true)
            (ok true)
        )
        err-owner-only
    )
)

(define-public (remove-judge (judge-address principal))
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-delete authorized-judges judge-address)
            (ok true)
        )
        err-owner-only
    )
)

;; Filing functions
(define-public (submit-filing (defendant principal) (document-hash (buff 32)))
    (let 
        (
            (new-id (+ (var-get filing-count) u1))
        )
        (map-set filings
            { case-id: new-id }
            {
                plaintiff: tx-sender,
                defendant: defendant,
                judge: contract-owner,
                status: "PENDING",
                timestamp: block-height,
                document-hash: document-hash
            }
        )
        (var-set filing-count new-id)
        (ok new-id)
    )
)

(define-public (update-case-status (case-id uint) (new-status (string-ascii 20)))
    (let (
        (filing (unwrap! (map-get? filings { case-id: case-id }) err-not-found))
    )
    (if (default-to false (map-get? authorized-judges tx-sender))
        (begin
            (map-set filings
                { case-id: case-id }
                (merge filing { status: new-status })
            )
            (ok true)
        )
        err-unauthorized
    ))
)

;; Read only functions
(define-read-only (get-filing (case-id uint))
    (ok (map-get? filings { case-id: case-id }))
)

(define-read-only (get-filing-count)
    (ok (var-get filing-count))
)

(define-read-only (is-judge (address principal))
    (ok (default-to false (map-get? authorized-judges address)))
)
