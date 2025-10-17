;; ------------------------------------------------------------
;; StreamPay - Simplified Streaming Payments Contract v1.1.0
;; ------------------------------------------------------------

;; Error codes
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))
(define-constant err-insufficient (err u402))
(define-constant err-stream-ended (err u403))

;; Stream states
(define-constant state-active u1)
(define-constant state-ended u2)

;; Data storage
(define-map streams 
  {id: uint}
  {owner: principal,
   recipient: principal,
   amount: uint,
   start: uint,
   end: uint,
   withdrawn: uint,
   state: uint})

(define-data-var next-id uint u1)

;; Helper
(define-read-only (get-current-block)
  (var-get next-id))  ;; Temporary replacement until we find proper block height access

;; Compute available amount based on elapsed blocks
(define-read-only (accrued (s (tuple (owner principal) (recipient principal) (amount uint) (start uint) (end uint) (withdrawn uint) (state uint))))
  (let ((current (get-current-block))
        (elapsed (- (if (> (get end s) current) current (get end s)) (get start s)))
        (duration (- (get end s) (get start s))))
    (if (> duration u0)
        (if (> (/ (* elapsed (get amount s)) duration) (get amount s))
            (get amount s)
            (/ (* elapsed (get amount s)) duration))
        u0)))

;; Create a stream: must send STX upfront
(define-public (create-stream (recipient principal) (amount uint) (duration uint))
  (let ((id (var-get next-id))
        (start (get-current-block)))
    (begin
      (asserts! (not (is-eq recipient tx-sender)) err-unauthorized)
      (asserts! (> amount u0) err-insufficient)
      (asserts! (> duration u0) err-insufficient)
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
      (map-set streams {id: id}
        {owner: tx-sender,
         recipient: recipient,
         amount: amount,
         start: start,
         end: (+ start duration),
         withdrawn: u0,
         state: state-active})
      (var-set next-id (+ id u1))
      (ok id))))

;; Withdraw accrued STX
(define-public (withdraw (id uint))
  (let ((stream (unwrap! (map-get? streams {id: id}) err-not-found)))
    (begin
      (asserts! (is-eq tx-sender (get recipient stream)) err-unauthorized)
      (asserts! (is-eq (get state stream) state-active) err-stream-ended)
      
      (let ((available (- (accrued stream) (get withdrawn stream)))
            (new-withdrawn (+ (get withdrawn stream) available)))
        (asserts! (> available u0) err-insufficient)
        (try! (stx-transfer? available (as-contract tx-sender) (get recipient stream)))
        (if (>= (get-current-block) (get end stream))
          (begin
            (asserts! (< id (var-get next-id)) err-not-found)
            (map-set streams {id: id}
              (merge stream {withdrawn: new-withdrawn, state: state-ended}))
            (ok {withdrawn: available, total-withdrawn: new-withdrawn}))
          (begin
            (asserts! (< id (var-get next-id)) err-not-found)
            (map-set streams {id: id}
              (merge stream {withdrawn: new-withdrawn}))
            (ok {withdrawn: available, total-withdrawn: new-withdrawn})))))))

;; Read stream details
(define-read-only (get-stream (id uint))
  (ok (unwrap! (map-get? streams {id: id}) err-not-found)))
