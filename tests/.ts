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
    name: "Test judge authorization",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const judge = accounts.get('wallet_3')!;

        let block = chain.mineBlock([
            Tx.contractCall('court-filing', 'add-judge', [
                types.principal(judge.address)
            ], deployer.address)
        ]);

        block.receipts[0].result.expectOk().expectBool(true);

        let checkJudge = chain.mineBlock([
            Tx.contractCall('court-filing', 'is-judge', [
                types.principal(judge.address)
            ], deployer.address)
        ]);

        checkJudge.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Test case status update by judge",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const judge = accounts.get('wallet_3')!;
        const plaintiff = accounts.get('wallet_1')!;
        const defendant = accounts.get('wallet_2')!;
        const documentHash = '0x1234567890123456789012345678901234567890123456789012345678901234';

        // First authorize judge
        let block = chain.mineBlock([
            Tx.contractCall('court-filing', 'add-judge', [
                types.principal(judge.address)
            ], deployer.address)
        ]);

        // Submit a case
        let filing = chain.mineBlock([
            Tx.contractCall('court-filing', 'submit-filing', [
                types.principal(defendant.address),
                types.buff(documentHash)
            ], plaintiff.address)
        ]);

        // Update case status
        let update = chain.mineBlock([
            Tx.contractCall('court-filing', 'update-case-status', [
                types.uint(1),
                types.ascii("APPROVED")
            ], judge.address)
        ]);

        update.receipts[0].result.expectOk().expectBool(true);
    }
});
