#!/usr/bin/env python3
"""
Endosymbiont Genome Data Collection
Downloads genome metadata for 22 endosymbiont genera from NCBI Assembly database.
"""

import json
import time
import sys
import os
from pathlib import Path
from Bio import Entrez

Entrez.email = "flow@ind.media"
DATA_DIR = Path("/home/node/.openclaw/workspace/drafts/valence-ingress/data/endosymbionts")
DATA_DIR.mkdir(parents=True, exist_ok=True)

# 22 genera with search terms
GENERA = [
    # (genus, search_term, host, lifestyle, time_since_symbiosis_mya, ancestor_size_mb)
    ("Buchnera", "Buchnera aphidicola[Organism]", "Aphids", "obligate", 180, 4.5),
    ("Carsonella", "Carsonella ruddii[Organism]", "Psyllids", "obligate", 200, 4.0),
    ("Blochmannia", "Blochmannia[Organism]", "Carpenter ants", "obligate", 150, 4.5),
    ("Wigglesworthia", "Wigglesworthia glossinidia[Organism]", "Tsetse flies", "obligate", 100, 4.0),
    ("Sulcia", "Sulcia muelleri[Organism]", "Sharpshooters, spittlebugs", "obligate", 260, 3.5),
    ("Nasuia", "Nasuia deltocephalinicola[Organism]", "Leafhoppers", "obligate", 200, 3.0),
    ("Karelsulcia", "Karelsulcia[Organism]", "Cicadas", "obligate", 200, 3.0),
    ("Tremblaya", "Tremblaya princeps[Organism]", "Mealybugs", "obligate", 150, 4.0),
    ("Moranella", "Moranella[Organism]", "Mealybugs", "obligate", 100, 3.5),
    ("Hodgkinia", "Hodgkinia cicadicola[Organism]", "Cicadas", "organellar", 200, 2.0),
    ("Zinderia", "Zinderia insecticola[Organism]", "Spittlebugs", "obligate", 200, 3.0),
    ("Portiera", "Candidatus Portiera[Organism]", "Whiteflies", "obligate", 150, 3.5),
    ("Baumannia", "Candidatus Baumannia[Organism]", "Sharpshooters", "obligate", 100, 3.5),
    ("Evansia", "Candidatus Evansia[Organism]", "Leafhoppers", "obligate", 150, 3.0),
    ("Uzinura", "Candidatus Uzinura[Organism]", "Armored scale insects", "obligate", 150, 3.0),
    ("Walczuchella", "Candidatus Walczuchella[Organism]", "Giant scale insects", "obligate", 150, 3.0),
    ("Gullanella", "Candidatus Gullanella[Organism]", "Scale insects", "obligate", 150, 3.0),
    ("Brownia", "Candidatus Brownia[Organism]", "Leafhoppers", "obligate", 100, 3.0),
    ("Desantisia", "Candidatus Desantisia[Organism]", "Cicadellids", "obligate", 100, 3.0),
    ("Ruthia", "Candidatus Ruthia magnifica[Organism]", "Giant clams (Lucinidae)", "obligate", 100, 4.0),
    ("Vesicomyosocius", "Candidatus Vesicomyosocius[Organism]", "Vesicomyid clams", "obligate", 100, 4.0),
    ("Endoriftia", "Candidatus Endoriftia persephone[Organism]", "Riftia tubeworms", "obligate", 100, 4.0),
]

def fetch_assembly_data(search_term, retmax=5):
    """Search for assemblies and return metadata."""
    try:
        handle = Entrez.esearch(db="assembly", term=search_term, retmax=retmax)
        record = Entrez.read(handle)
        handle.close()
        ids = record["IdList"]
        if not ids:
            return None
        handle = Entrez.esummary(db="assembly", id=",".join(ids))
        rec = Entrez.read(handle)
        handle.close()
        results = []
        for summary in rec["DocumentSummarySet"]["DocumentSummary"]:
            # Get genome size from stats file
            genome_size = summary.get("GenomeSize", None)
            if genome_size is None or genome_size == "":
                genome_size = None
            else:
                try:
                    genome_size = int(genome_size)
                except (ValueError, TypeError):
                    genome_size = None
            
            contig_n50 = summary.get("ContigN50", None)
            scaffold_n50 = summary.get("ScaffoldN50", None)
            coverage = summary.get("Coverage", None)
            status = summary.get("AssemblyStatus", "")
            org = summary.get("Organism", "")
            species = summary.get("SpeciesName", "")
            ftp_refseq = summary.get("FtpPath_RefSeq", "")
            ftp_genbank = summary.get("FtpPath_GenBank", "")
            accession = summary.get("AssemblyAccession", "")
            taxid = summary.get("SpeciesTaxid", "")
            
            results.append({
                "organism": org,
                "species": species,
                "assembly_status": status,
                "assembly_accession": accession,
                "taxid": taxid,
                "genome_size": genome_size,
                "contig_n50": contig_n50,
                "scaffold_n50": scaffold_n50,
                "coverage": coverage,
                "ftp_refseq": ftp_refseq,
                "ftp_genbank": ftp_genbank,
            })
        return results
    except Exception as e:
        print(f"  Error: {e}")
        return None

def fetch_genome_size_from_stats(ftp_path):
    """Try to get genome size from the assembly stats file."""
    if not ftp_path:
        return None
    stats_url = ftp_path.replace("ftp://", "https://") + "/" + ftp_path.split("/")[-1] + "_assembly_stats.txt"
    try:
        import urllib.request
        with urllib.request.urlopen(stats_url, timeout=30) as response:
            data = response.read().decode()
            for line in data.split("\n"):
                if line.startswith("# Total sequence length"):
                    parts = line.split("\t")
                    if len(parts) >= 2:
                        return int(parts[1].strip())
                elif "total-length" in line.lower() or "total sequence length" in line.lower():
                    import re
                    nums = re.findall(r'\d+', line)
                    if nums:
                        return int(nums[0])
        return None
    except Exception as e:
        return None

def fetch_genbank_summary(assembly_accession):
    """Get summary from GenBank for gene count."""
    try:
        # Use the assembly accession to find the genbank record
        handle = Entrez.esearch(db="nucleotide", term=f"{assembly_accession}[Assembly]", retmax=2)
        record = Entrez.read(handle)
        handle.close()
        return record.get("Count", "0")
    except Exception:
        return "0"

def main():
    all_data = []
    
    for i, (genus, search_term, host, lifestyle, time_mya, anc_size) in enumerate(GENERA):
        print(f"\n[{i+1}/22] {genus} ({lifestyle}) — searching: {search_term}")
        results = fetch_assembly_data(search_term, retmax=5)
        
        if results:
            # Get the best assembly (prefer complete genome, refseq)
            best = None
            for r in results:
                if r["assembly_status"] == "Complete Genome":
                    if best is None or (r["assembly_accession"].startswith("GCF") and not best["assembly_accession"].startswith("GCF")):
                        best = r
            if best is None and results:
                # Just pick the first one
                best = results[0]
            
            if best:
                print(f"  Best: {best['organism']} | {best['assembly_accession']} | {best['assembly_status']} | size={best['genome_size']}")
                
                # Try to get genome size from stats file if not available
                genome_size = best["genome_size"]
                if genome_size is None or genome_size == 0:
                    print(f"  Fetching genome size from stats file...")
                    for ftp in [best["ftp_refseq"], best["ftp_genbank"]]:
                        if ftp:
                            size = fetch_genome_size_from_stats(ftp)
                            if size:
                                genome_size = size
                                print(f"  Got genome size: {genome_size}")
                                break
                
                entry = {
                    "genus": genus,
                    "organism": best["organism"],
                    "species": best["species"],
                    "assembly_accession": best["assembly_accession"],
                    "assembly_status": best["assembly_status"],
                    "genome_size_bp": genome_size,
                    "genome_size_mb": round(genome_size / 1e6, 4) if genome_size else None,
                    "contig_n50": best["contig_n50"],
                    "scaffold_n50": best["scaffold_n50"],
                    "taxid": best["taxid"],
                    "host": host,
                    "lifestyle": lifestyle,
                    "time_since_symbiosis_mya": time_mya,
                    "ancestor_size_mb": anc_size,
                }
                all_data.append(entry)
            else:
                print(f"  No suitable assembly found")
                entry = {
                    "genus": genus,
                    "organism": f"{genus} sp.",
                    "species": "",
                    "assembly_accession": "",
                    "assembly_status": "",
                    "genome_size_bp": None,
                    "genome_size_mb": None,
                    "contig_n50": None,
                    "scaffold_n50": None,
                    "taxid": "",
                    "host": host,
                    "lifestyle": lifestyle,
                    "time_since_symbiosis_mya": time_mya,
                    "ancestor_size_mb": anc_size,
                }
                all_data.append(entry)
        else:
            print(f"  No results found")
            entry = {
                "genus": genus,
                "organism": f"{genus} sp.",
                "species": "",
                "assembly_accession": "",
                "assembly_status": "",
                "genome_size_bp": None,
                "genome_size_mb": None,
                "contig_n50": None,
                "scaffold_n50": None,
                "taxid": "",
                "host": host,
                "lifestyle": lifestyle,
                "time_since_symbiosis_mya": time_mya,
                "ancestor_size_mb": anc_size,
            }
            all_data.append(entry)
        
        # Be nice to NCBI
        time.sleep(0.5)
    
    # Save
    output = DATA_DIR / "endosymbiont_genome_data.json"
    with open(output, "w") as f:
        json.dump(all_data, f, indent=2)
    print(f"\nSaved {len(all_data)} entries to {output}")
    
    # Also save as CSV
    import csv
    csv_output = DATA_DIR / "endosymbiont_genome_data.csv"
    with open(csv_output, "w", newline="") as f:
        if all_data:
            writer = csv.DictWriter(f, fieldnames=all_data[0].keys())
            writer.writeheader()
            writer.writerows(all_data)
    print(f"Saved CSV to {csv_output}")
    
    # Summary
    print("\n=== SUMMARY ===")
    for d in all_data:
        size = f"{d['genome_size_mb']:.3f} Mb" if d['genome_size_mb'] else "N/A"
        print(f"{d['genus']:15s} | {d['lifestyle']:12s} | {size:12s} | {d['assembly_status']:20s} | {d['assembly_accession']:20s}")

if __name__ == "__main__":
    main()