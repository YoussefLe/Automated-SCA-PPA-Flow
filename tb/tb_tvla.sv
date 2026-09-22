`timescale 1ns/1ps

module tb_tvla;

    // Signaux de test
    logic clk;
    logic rst_n;
    logic start;
    logic done;
    logic [127:0] key;
    logic [127:0] plaintext;
    logic [127:0] ciphertext;

    // Variables pour l'analyse TVLA
    int fd; // File descriptor pour le fichier texte
    bit is_random;
    
    // Constantes TVLA
    localparam logic [127:0] FIXED_KEY   = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    localparam logic [127:0] FIXED_TEXT  = 128'h3243f6a8885a308d313198a2e0370734;
    localparam int NUM_TRACES            = 10000; // Nombre total de chiffrements

    // Instanciation du Design VHDL (L'AES)
    aes_core uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .done(done),
        .key(key),
        .plaintext(plaintext),
        .ciphertext(ciphertext)
    );

    // Génération de l'horloge (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Processus Principal TVLA
    initial begin
        // 1. Ouvrir le fichier pour logger les classes TVLA
        fd = $fopen("tvla_labels.txt", "w");
        if (fd == 0) begin
            $display("Erreur : Impossible de créer tvla_labels.txt");
            $finish;
        end

        // 2. Initialisation et Reset
        start = 0;
        key = FIXED_KEY;
        rst_n = 0;
        #20 rst_n = 1; // Relâcher le reset
        #10;

        // 3. Boucle d'injection des vecteurs TVLA
        for (int i = 0; i < NUM_TRACES; i++) begin
            
            // Tirage au sort : 0 (Fixe) ou 1 (Aléatoire)
            is_random = $urandom_range(0, 1);
            
            if (is_random == 1'b1) begin
                // Générer 128 bits aléatoires (4 x 32 bits car $urandom donne 32 bits)
                plaintext = {$urandom, $urandom, $urandom, $urandom};
                $fdisplay(fd, "1"); // Logger dans le fichier
            end else begin
                plaintext = FIXED_TEXT;
                $fdisplay(fd, "0"); // Logger dans le fichier
            end

            // 4. Lancer le chiffrement
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;

            // 5. Attendre la fin du chiffrement (signal done)
            wait(done == 1'b1);
            
            // Laisser quelques cycles de "repos" (Idle) pour séparer les traces de puissance
            repeat(3) @(posedge clk); 
        end

        // 6. Fin de simulation
        $fclose(fd);
        $display("Simulation TVLA terminée. Fichier tvla_labels.txt généré.");
        $finish;
    end

    // Dumping des waveforms (VCD) pour Joules
    // Cette partie sera activée par Xcelium via un script TCL externe
    
endmodule