import pandas as pd
import argparse

# Lista ordenada dos genes
ORDERED_GENES = ['2K', 'C', 'E', 'M', 'NS1', 'NS2A', 'NS2B', 'NS3', 'NS4A', 'NS4B', 'NS5', 'pr']

def find_important_mutations(mutations):
    """
    Encontra todas as mutações importantes para cada gene.
    Retorna uma lista de tuplas onde o primeiro elemento é o gene e o segundo é a mutação.
    """
    important_mutations = []
    for mutation in mutations:
        gene, aminoacid = mutation.split(':')
        aminoacids = aminoacid.split(',')
        for aa in aminoacids:
            important_mutations.append((gene, aa))
    return important_mutations

def transform_table(input_file, output_file, lineage_output_file):
    # Leitura do DataFrame
    df = pd.read_csv(input_file, sep='\t')

    # Criar uma cópia da coluna "Lineage Annotation" original
    original_lineage = df['Lineage Annotation'].copy()

    # Criar uma lista para armazenar as linhas
    all_rows = []  # Todas as linhas

    # Iterar sobre as linhas do DataFrame original
    for _, row in df.iterrows():
        # Ignorar as linhas com clade "Root"
        if row['Lineage Annotation'] == 'Root':
            continue

        # Adicionar linha de cabeçalho antes de cada clade (apenas para grupos de linhagem e sublinhagem)
        if len(row['Lineage Annotation']) > 1 and (not all_rows or all_rows[-1].get('clade') != row['Lineage Annotation']):
            parent_lineage = row['Parent Lineage'] if pd.notna(row['Parent Lineage']) else ''
            clade_info = {
                'clade': row['Lineage Annotation'],
                'gene': 'clade',
                'site': parent_lineage,
                'alt': ''
            }
            all_rows.append(clade_info)

        # Separar as mutações
        mutations = row['Signature Mutations'].split(',')

        # Encontrar todas as mutações importantes para esta linha
        important_mutations = find_important_mutations(mutations)

        # Adicionar as mutações formatadas à lista
        previous_gene = None
        for gene, mutation in important_mutations:
            # Verificar se o gene é alfanumericamente maior ou igual ao anterior
            if previous_gene is not None and ORDERED_GENES.index(gene) < ORDERED_GENES.index(previous_gene):
                break  # Se o gene for menor, parar de escrever e passar para o próximo clado
            site, alt = mutation[:-1], mutation[-1]  # Separar site e alt
            formatted_mutation = {
                'clade': row['Lineage Annotation'],
                'gene': gene,
                'site': site[1:],  # Eliminar o primeiro caractere do site
                'alt': alt
            }
            all_rows.append(formatted_mutation)
            previous_gene = gene

        # Adicionar uma linha em branco após cada clade
        all_rows.append({})

    # Criar um DataFrame a partir da lista de linhas
    all_df = pd.DataFrame(all_rows)

    # Salvar o DataFrame principal em um arquivo TSV
    all_df.to_csv(output_file, sep='\t', index=False)

    # Criar um DataFrame para a coluna "Lineage Annotation" original e a nova
    lineage_df = pd.DataFrame({'Original Lineage Annotation': original_lineage, 'New Lineage Annotation': df['Lineage Annotation']})

    # Salvar o DataFrame da coluna "Lineage Annotation" em um arquivo TSV
    lineage_df.to_csv(lineage_output_file, sep='\t', index=False)

if __name__ == "__main__":
    # Configurar o parser de argumentos
    parser = argparse.ArgumentParser(description='Transformar tabela de mutações.')
    parser.add_argument('-i', '--input', help='Arquivo de entrada (TSV)', required=True)
    parser.add_argument('-o', '--output', help='Arquivo de saída (TSV)', required=True)
    parser.add_argument('-l', '--lineage-output', help='Arquivo de saída para a coluna Lineage Annotation (TSV)', required=True)

    # Analisar os argumentos da linha de comando
    args = parser.parse_args()

    # Chamar a função com os argumentos fornecidos
    transform_table(args.input, args.output, args.lineage_output)
