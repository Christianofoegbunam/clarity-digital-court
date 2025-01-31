import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test case filing submission",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const plaintiff = accounts.get('wallet_1')!;
        const defendant = accounts.get('wallet_2')!;
        const documentHash = '0x1234567890123456789012345678901234567890123456789012345678901234';

        let block = chain.mineBlock([
            Tx.contractCall('court-filing', 'submit-filing', [
                types.principal(defendant.address),
                types.buff(documentHash)
            ], plaintiff.address)
        ]);

        block.receipts[0].result.expectOk().expectUint(1);
    }
});

Clarinet.test({
    name: "Test evidence submission and review",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const plaintiff = accounts.get('wallet_1')!;
        const defendant = accounts.get('wallet_2')!;
        const judge = accounts.get('wallet_3')!;
        const documentHash = '0x1234567890123456789012345678901234567890123456789012345678901234';
        const evidenceHash = '0x5678901234567890123456789012345678901234567890123456789012345678';

        // Submit case filing
        let block = chain.mineBlock([
            Tx.contractCall('court-filing', 'submit-filing', [
                types.principal(defendant.address),
                types.buff(documentHash)
            ], plaintiff.address)
        ]);

        // Authorize judge
        chain.mineBlock([
            Tx.contractCall('court-filing', 'add-judge', [
                types.principal(judge.address)
            ], deployer.address)
        ]);

        // Submit evidence
        let evidence = chain.mineBlock([
            Tx.contractCall('court-filing', 'submit-evidence', [
                types.uint(1),
                types.buff(evidenceHash),
                types.ascii("Key evidence document")
            ], plaintiff.address)
        ]);

        evidence.receipts[0].result.expectOk().expectUint(1);

        // Review evidence
        let review = chain.mineBlock([
            Tx.contractCall('court-filing', 'review-evidence', [
                types.uint(1),
                types.uint(1),
                types.ascii("ACCEPTED")
            ], judge.address)
        ]);

        review.receipts[0].result.expectOk().expectBool(true);
    }
});
