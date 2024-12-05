;; Decentralized Book Publishing Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

;; Data Variables
(define-data-var next-book-id uint u1)

;; Data Maps
(define-map books
    uint 
    {
        title: (string-utf8 256),
        author: principal,
        isbn: (string-ascii 13),
        price: uint,
        published: bool,
        royalty-percentage: uint
    }
)

(define-map author-books 
    principal 
    (list 100 uint)
)

(define-map book-purchases
    {book-id: uint, buyer: principal}
    {purchased-at: uint}
)

;; Public Functions
(define-public (register-book (title (string-utf8 256)) (isbn (string-ascii 13)) (price uint) (royalty uint))
    (let
        (
            (book-id (var-get next-book-id))
            (author-books-list (default-to (list) (map-get? author-books tx-sender)))
        )
        (asserts! (< royalty u100) (err u104))
        (try! (map-set books book-id {
            title: title,
            author: tx-sender,
            isbn: isbn,
            price: price,
            published: false,
            royalty-percentage: royalty
        }))
        (map-set author-books tx-sender (append author-books-list book-id))
        (var-set next-book-id (+ book-id u1))
        (ok book-id)
    )
)

(define-public (publish-book (book-id uint))
    (let
        ((book (unwrap! (map-get? books book-id) err-not-found)))
        (asserts! (is-eq (get author book) tx-sender) err-unauthorized)
        (try! (map-set books book-id (merge book {published: true})))
        (ok true)
    )
)

(define-public (purchase-book (book-id uint))
    (let
        (
            (book (unwrap! (map-get? books book-id) err-not-found))
            (price (get price book))
            (author (get author book))
            (royalty (get royalty-percentage book))
            (royalty-amount (/ (* price royalty) u100))
            (platform-fee (- price royalty-amount))
        )
        (asserts! (get published book) err-unauthorized)
        ;; Transfer payment to author
        (try! (stx-transfer? royalty-amount tx-sender author))
        ;; Transfer platform fee
        (try! (stx-transfer? platform-fee tx-sender contract-owner))
        ;; Record purchase
        (map-set book-purchases {book-id: book-id, buyer: tx-sender} {purchased-at: block-height})
        (ok true)
    )
)

;; Read Only Functions
(define-read-only (get-book (book-id uint))
    (map-get? books book-id)
)

(define-read-only (get-author-books (author principal))
    (map-get? author-books author)
)

(define-read-only (has-purchased (book-id uint) (buyer principal))
    (is-some (map-get? book-purchases {book-id: book-id, buyer: buyer}))
)
