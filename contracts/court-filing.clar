;; Digital Court Filing System Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-evidence (err u103))

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

;; Evidence Management
(define-map case-evidence
    { case-id: uint, evidence-id: uint }
    {
        submitter: principal,
        evidence-hash: (buff 32),
        description: (string-ascii 256),
        submission-time: uint,
        status: (string-ascii 20)
    }
)

(define-data-var evidence-count uint u0)
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

;; Evidence functions
(define-public (submit-evidence 
    (case-id uint)
    (evidence-hash (buff 32))
    (description (string-ascii 256)))
    (let
        (
            (filing (unwrap! (map-get? filings { case-id: case-id }) err-not-found))
            (new-evidence-id (+ (var-get evidence-count) u1))
        )
        (asserts! (or
            (is-eq tx-sender (get plaintiff filing))
            (is-eq tx-sender (get defendant filing))
            (default-to false (map-get? authorized-judges tx-sender)))
            err-unauthorized)
        (map-set case-evidence
            { case-id: case-id, evidence-id: new-evidence-id }
            {
                submitter: tx-sender,
                evidence-hash: evidence-hash,
                description: description,
                submission-time: block-height,
                status: "SUBMITTED"
            }
        )
        (var-set evidence-count new-evidence-id)
        (ok new-evidence-id)
    )
)

(define-public (review-evidence
    (case-id uint)
    (evidence-id uint)
    (new-status (string-ascii 20)))
    (let (
        (evidence (unwrap! (map-get? case-evidence { case-id: case-id, evidence-id: evidence-id }) err-not-found))
    )
    (if (default-to false (map-get? authorized-judges tx-sender))
        (begin
            (map-set case-evidence
                { case-id: case-id, evidence-id: evidence-id }
                (merge evidence { status: new-status })
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

(define-read-only (get-evidence (case-id uint) (evidence-id uint))
    (ok (map-get? case-evidence { case-id: case-id, evidence-id: evidence-id }))
)

(define-read-only (get-evidence-count)
    (ok (var-get evidence-count))
)
