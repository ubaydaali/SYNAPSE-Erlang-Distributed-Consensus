import streamlit as st
import subprocess
import os
import time

st.set_page_config(page_title="SYNAPSE Erlang", page_icon="⚡", layout="wide")

st.markdown("""
    <style>
    .footer { position: fixed; left: 0; bottom: 0; width: 100%; background-color: #0e1117; color: white; text-align: center; padding: 15px 0; border-top: 1px solid #4a4a4a; z-index: 999; }
    .footer a { color: #64ffda; text-decoration: none; margin: 0 15px; font-size: 20px; transition: 0.3s; }
    .footer a:hover { color: #ffffff; text-shadow: 0 0 10px #64ffda; }
    </style>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    """, unsafe_allow_html=True)

st.title("⚡ SYNAPSE: Massively Parallel Consensus Engine")
st.markdown("##### *Spawning 10,000 isolated Erlang processes simultaneously for instant transaction validation.*")
st.divider()

if st.button("🚀 Spawn 10,000 Concurrent Actors", type="primary"):
    
    os.makedirs('erlang_engine', exist_ok=True)
    os.makedirs('data/output', exist_ok=True)
    os.makedirs('data/input', exist_ok=True)
    
    # [التحديث المعماري] توليد البيانات بأسطر حقيقية قبل تشغيل إرلانغ مباشرة
    with st.spinner("Generating 10,000 live transactions with injected anomalies..."):
        with open('data/input/transactions.dat', 'w', encoding='utf-8') as f:
            for i in range(1, 10001):
                amount = 100 if i % 1500 != 0 else 85000
                f.write(f"TX{i:06d} {amount}\n") # السطر الجديد الحقيقي هنا
    
    with st.spinner("Compiling Erlang Actor Model..."):
        try:
            subprocess.run(["erlc", "-o", "erlang_engine", "src/synapse_core.erl"], check=True)
        except FileNotFoundError:
            st.warning("⚠️ Local Erlang Compiler Missing. Deploy to Streamlit Cloud.")
            st.stop()
            
    start_time = time.time()
    with st.spinner("10,000 Nodes spawned. Achieving distributed consensus..."):
        subprocess.run(["erl", "-noshell", "-pa", "erlang_engine", "-s", "synapse_core", "start"])
    end_time = time.time()
    
    st.success(f"✅ Consensus Reached in {end_time - start_time:.4f} seconds!")
    
    try:
        with open('data/output/consensus_report.txt', 'r', encoding='utf-8') as f:
            st.code(f.read(), language="text")
    except FileNotFoundError:
        st.warning("Execution failed.")
        
    st.info("💡 **Architectural Note:** This isn't a loop. The engine literally spawned 10,000 living independent processes in memory, validated the ledger, and killed them instantly.")

st.markdown("""
    <div class="footer">
        <a href="https://github.com/ubaydaali" target="_blank"><i class="fab fa-github"></i></a>
        <a href="https://www.linkedin.com/in/ubayda-ali-95972a406/" target="_blank"><i class="fab fa-linkedin"></i></a>
        <a href="https://t.me/obedaale" target="_blank"><i class="fab fa-telegram"></i></a>
        <a href="https://onws.net" target="_blank"><i class="fas fa-globe"></i></a>
        <br><span style="font-size:12px; color:#888;">Lead Architect: UBAYDA ALİ | Engineered with Erlang & Python</span>
    </div>
    """, unsafe_allow_html=True)
