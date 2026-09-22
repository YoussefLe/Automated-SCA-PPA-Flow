`timescale 1ns/1ps

// Ce module "aplatit" les types OpenTitan pour qu'ils soient lisibles par le VHDL
module aes_cipher_core_flat (
    input  logic         clk_i,
    input  logic         rst_ni,
    
    // Interface de contrôle simple
    input  logic         start_i,
    output logic         done_o,
    
    // Clé divisée en 2 parts (Shares) pour le masquage DOM
    input  logic [127:0] key_share0_i,
    input  logic [127:0] key_share1_i,
    
    // Données (Le masquage du plaintext est géré en interne par OpenTitan)
    input  logic [127:0] plaintext_i,
    output logic [127:0] ciphertext_o
);

    import aes_pkg::*; // Importation des constantes OpenTitan

    // Signaux internes pour l'IP OpenTitan
    logic [7:0][31:0] key_init_array [2];
    logic [3:0][31:0] state_init_array;
    logic [3:0][31:0] data_out_array;
    
    // Assignation (Aplatissement 1D vers Tableaux 2D OpenTitan)
    // On mappe les 128 bits sur la partie basse des 256 bits attendus par l'IP
    assign key_init_array[0] = {128'b0, key_share0_i}; 
    assign key_init_array[1] = {128'b0, key_share1_i};
    assign state_init_array  = plaintext_i;
    assign ciphertext_o      = data_out_array;

    // Instanciation du cœur OpenTitan (Configuré pour le Masquage DOM)
    aes_cipher_core #(
        .AES192Enable(1'b0),
        .Masking(1'b1),               // ACTIVATION DU MASQUAGE
        .SBoxImpl(aes_pkg::SBoxImplDom) // CHOIX DE LA S-BOX : DOM (Canright)
    ) u_aes_core (
        .clk_i             (clk_i),
        .rst_ni            (rst_ni),
        .in_valid_i        (start_i),
        .in_ready_o        (), 
        .out_valid_o       (done_o),
        .out_ready_i       (1'b1),
        .crypt_i           (start_i),
        .crypt_o           (),
        .dec_key_gen_i     (1'b0),
        .dec_key_gen_o     (),
        .key_clear_i       (1'b0),
        .key_clear_o       (),
        .data_out_clear_i  (1'b0),
        .data_out_clear_o  (),
        .mux_sel_err_o     (),
        .sp2v_err_o        (),
        .prd_clearing_i    (128'b0),
        .op_i              (aes_pkg::AES_ENC), // Opération : Chiffrement
        .state_init_i      (state_init_array),
        .key_init_i        (key_init_array),
        .data_out_o        (data_out_array)
    );

endmodule