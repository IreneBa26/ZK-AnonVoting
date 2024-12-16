pragma circom 2.0.0;

include "node_modules/circomlib/circuits/poseidon.circom";
include "node_modules/circomlib/circuits/comparators.circom";

template PrivateVoteSelection(candidates) {
    // Private inputs 
    signal input voter_secret;        // Voter's private key
    signal input vote_commitment;     // Cryptographic commitment of vote
    signal input selected_candidate_index;  // Index of selected candidate

    // Public inputs
    signal input candidate_list[candidates];  // List of candidates
    signal output vote_valid;                 // Validation output

    // Commitment verification component
    component hasher = Poseidon(2);  // Cryptographic hash function

    // Candidate index validation
    component index_check = LessThan(candidates);

    // Commitment generation
    hasher.inputs[0] <== voter_secret;
    hasher.inputs[1] <== selected_candidate_index;

    // Verify commitment matches generated hash
    vote_commitment === hasher.out;

    // Validate candidate index is within range
    index_check.in[0] <== selected_candidate_index;
    index_check.in[1] <== candidates;
    index_check.out === 1;

    // Ensure single candidate selection
    signal one_hot[candidates]; // Predeclare the array of signals
    signal temp_sum[candidates]; // Temporary signal array for sum
    signal one_hot_sum;

    // Initialize signals
    for (var i = 0; i < candidates; i++) {
        one_hot[i] <== 0; // Explicitly initialize each signal

        // Enforce (selected_candidate_index - i) * one_hot[i] = 0
        (selected_candidate_index - i) * one_hot[i] === 0;

        // Enforce one_hot[i] is binary (0 or 1)
        one_hot[i] * (one_hot[i] - 1) === 0;
    }

    // Compute the cumulative sum
    temp_sum[0] <== one_hot[0];
    for (var i = 1; i < candidates; i++) {
        temp_sum[i] <== temp_sum[i - 1] + one_hot[i];
    }

    // Assign the final sum
    one_hot_sum <== temp_sum[candidates - 1];

    // Ensure exactly one candidate is selected
    one_hot_sum === 1;

    // Output validation flag
    vote_valid <== 1;
}


// Example usage template
template VotingProtocol() {
    var NUM_CANDIDATES = 3;
    signal input candidates[NUM_CANDIDATES];
    signal input voter_secret;
    signal input vote_commitment;
    signal input selected_candidate_index;

    component voteCircuit = PrivateVoteSelection(NUM_CANDIDATES);
    
    // Wire up inputs
    for (var i = 0; i < NUM_CANDIDATES; i++) {
        voteCircuit.candidate_list[i] <== candidates[i];
    }
    voteCircuit.voter_secret <== voter_secret;
    voteCircuit.vote_commitment <== vote_commitment;
    voteCircuit.selected_candidate_index <== selected_candidate_index;
}

component main = VotingProtocol();