import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register and publish a book",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('book-publisher', 'register-book', [
                types.utf8("Test Book"),
                types.ascii("1234567890123"),
                types.uint(1000000),
                types.uint(70)
            ], wallet1.address),
            Tx.contractCall('book-publisher', 'publish-book', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        block.receipts[1].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Can purchase a published book",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const author = accounts.get('wallet_1')!;
        const buyer = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('book-publisher', 'register-book', [
                types.utf8("Test Book"),
                types.ascii("1234567890123"),
                types.uint(1000000),
                types.uint(70)
            ], author.address),
            Tx.contractCall('book-publisher', 'publish-book', [
                types.uint(1)
            ], author.address),
            Tx.contractCall('book-publisher', 'purchase-book', [
                types.uint(1)
            ], buyer.address)
        ]);
        
        block.receipts[2].result.expectOk().expectBool(true);
    }
});
