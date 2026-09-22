library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity aes128_core_masked is
    port (
        clk         : in  std_logic;
        rst_n       : in  std_logic;
        start       : in  std_logic;
        done        : out std_logic;
        key         : in  std_logic_vector(127 downto 0);
        plaintext   : in  std_logic_vector(127 downto 0);
        ciphertext  : out std_logic_vector(127 downto 0)
    );
end entity aes128_core_masked;

architecture structural of aes128_core_masked is

    -- Masques et Shares
    signal prng_mask    : std_logic_vector(127 downto 0);
    signal key_share_0  : std_logic_vector(127 downto 0);
    signal key_share_1  : std_logic_vector(127 downto 0);

    -- 1. Le PRNG (Générateur de Nombres Aléatoires que tu devras coder ou sourcer)
    component lfsr_128 is
        port (
            clk      : in  std_logic;
            rst_n    : in  std_logic;
            rand_out : out std_logic_vector(127 downto 0)
        );
    end component;

    -- 2. L'interface vers le Flat Wrapper SystemVerilog d'OpenTitan
    component aes_cipher_core_flat is
        port (
            clk_i        : in  std_logic;
            rst_ni       : in  std_logic;
            start_i      : in  std_logic;
            done_o       : out std_logic;
            key_share0_i : in  std_logic_vector(127 downto 0);
            key_share1_i : in  std_logic_vector(127 downto 0);
            plaintext_i  : in  std_logic_vector(127 downto 0);
            ciphertext_o : out std_logic_vector(127 downto 0)
        );
    end component;

begin

    -- Instanciation du PRNG pour générer le masque initial de la clé
    U_PRNG : lfsr_128 port map (
        clk      => clk,
        rst_n    => rst_n,
        rand_out => prng_mask
    );

    -- Séparation de la clé en deux domaines (Boolean Masking)
    -- Share 1 reçoit le masque aléatoire
    -- Share 0 reçoit la clé masquée (key XOR mask)
    key_share_1 <= prng_mask;
    key_share_0 <= key xor prng_mask;

    -- Instanciation de l'IP OpenTitan
    -- Note : Le masquage du plaintext et l'injection d'aléa dans les S-Boxes
    -- sont gérés automatiquement à l'intérieur du cœur OpenTitan.
    U_OPENTITAN_AES : aes_cipher_core_flat port map (
        clk_i        => clk,
        rst_ni       => rst_n,
        start_i      => start,
        done_o       => done,
        key_share0_i => key_share_0,
        key_share1_i => key_share_1,
        plaintext_i  => plaintext,
        ciphertext_o => ciphertext
    );

end architecture structural;