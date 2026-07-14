

Instalar Python 3.9 mantendo versão nativa no Oracle Linux 7.9

----------------------------------------------------------------
# Dependências de compilação
----------------------------------------------------------------
yum groupinstall "Development Tools"
yum install openssl-devel bzip2-devel libffi-devel \
            zlib-devel readline-devel sqlite-devel

----------------------------------------------------------------
# Baixar Python 3.9
----------------------------------------------------------------

wget https://www.python.org/ftp/python/3.9.18/Python-3.9.18.tgz
tar xzf Python-3.9.18.tgz
cd Python-3.9.18

----------------------------------------------------------------
# Compilar — altinstall não sobrescreve links simbólicos
----------------------------------------------------------------

./configure --enable-optimizations
make -j$(nproc) altinstall

----------------------------------------------------------------
# Verificar
----------------------------------------------------------------
python3.9 --version     # → 3.9.18
python --version        # → 2.7.x (nativo intacto)
