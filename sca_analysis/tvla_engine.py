import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import os

def load_data(power_csv_path, labels_txt_path, samples_per_trace):
    print("[1/4] Chargement des données...")
    
    # 1. Charger les labels (0 = Fixe, 1 = Aléatoire)
    with open(labels_txt_path, 'r') as f:
        labels = np.array([int(line.strip()) for line in f.readlines()])
    
    # 2. Charger les données de puissance de Joules
    # Joules exporte souvent une longue colonne continue. 
    # On la lit et on la "découpe" (reshape) en une matrice 2D : (Nombre de Traces x Echantillons par Trace)
    df = pd.read_csv(power_csv_path)
    # Supposons que la colonne s'appelle 'Total_Power'
    power_continuous = df['Total_Power'].values 
    
    num_traces = len(labels)
    # Redimensionnement de la vague continue en matrice de traces individuelles
    traces_matrix = power_continuous[:num_traces * samples_per_trace].reshape((num_traces, samples_per_trace))
    
    return traces_matrix, labels

def compute_t_test(traces, labels):
    print("[2/4] Tri des traces et calcul statistique (Welch's T-test)...")
    
    # Séparation mathématique rapide grâce aux masques booléens NumPy
    group_fixed = traces[labels == 0]
    group_random = traces[labels == 1]
    
    n_fixed = len(group_fixed)
    n_random = len(group_random)
    
    print(f" -> Traces Fixes (A): {n_fixed}")
    print(f" -> Traces Aléatoires (B): {n_random}")
    
    # Calcul des Moyennes (mu) axe vertical (axis=0)
    mu_fixed = np.mean(group_fixed, axis=0)
    mu_random = np.mean(group_random, axis=0)
    
    # Calcul des Variances (s^2)
    var_fixed = np.var(group_fixed, axis=0)
    var_random = np.var(group_random, axis=0)
    
    # Application stricte de la formule du Welch's T-test
    # On ajoute un très petit epsilon (1e-8) au dénominateur pour éviter la division par zéro
    numerator = mu_fixed - mu_random
    denominator = np.sqrt((var_fixed / n_fixed) + (var_random / n_random) + 1e-8)
    
    t_values = numerator / denominator
    return t_values

def plot_tvla(t_values, output_path):
    print("[3/4] Génération du graphique de certification TVLA...")
    
    plt.figure(figsize=(12, 6))
    plt.plot(t_values, color='black', linewidth=0.8, label="T-Test Value")
    
    # Ajout des seuils critiques absolus de l'industrie (+4.5 et -4.5)
    plt.axhline(y=4.5, color='red', linestyle='--', label="Seuil de fuite (+4.5)")
    plt.axhline(y=-4.5, color='red', linestyle='--', label="Seuil de fuite (-4.5)")
    
    # Esthétique du graphique
    plt.title("Test Vector Leakage Assessment (TVLA) - AES-128 Non Protégé")
    plt.xlabel("Temps (Cycles / Échantillons)")
    plt.ylabel("T-Statistic Value")
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    
    # Sauvegarde de l'image
    plt.savefig(output_path, dpi=300)
    print(f"[4/4] Résultat sauvegardé dans : {output_path}")
    
    # Vérification automatique du Fail/Pass
    max_t = np.max(np.abs(t_values))
    if max_t > 4.5:
        print(f"\n[ ALERTE ] FUITE MATÉRIELLE DÉTECTÉE ! T-Value Max: {max_t:.2f} (> 4.5)")
    else:
        print(f"\n[ SUCCÈS ] AUCUNE FUITE DÉTECTÉE. T-Value Max: {max_t:.2f} (<= 4.5)")

if __name__ == "__main__":
    # Chemins relatifs depuis le dossier sca_analysis/
    CSV_FILE = "../traces/power_traces_export.csv"
    LABELS_FILE = "../tb/tvla_labels.txt"
    OUTPUT_IMAGE = "../reports/tvla_result_unprotected.png"
    
    # Nombre de cycles d'horloge mesurés par chiffrement (ex: 15 cycles pour un AES itératif avec idle)
    SAMPLES_PER_TRACE = 15 
    
    if os.path.exists(CSV_FILE) and os.path.exists(LABELS_FILE):
        traces, labels = load_data(CSV_FILE, LABELS_FILE, SAMPLES_PER_TRACE)
        t_stat = compute_t_test(traces, labels)
        plot_tvla(t_stat, OUTPUT_IMAGE)
    else:
        print("Erreur : Fichiers de puissance ou de labels introuvables. Lancez d'abord le flot EDA Cadence.")