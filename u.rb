#!/usr/bin/ruby
require 'net/ssh'
require 'net/scp'

# Autor: Garikiotz Arellano

# PRE: Verdad
# POST: Devuelve las maquinas que hay en el archivo <hosts_file>
def read_hosts(hosts_file)
  File.read(hosts_file).split("\n").map(&:strip)
end

# PRE: <grupo_o_maquina> es un string que representa un grupo o una maquina
#      <hosts> es el contendi del archivo hosts
# POST: Devuelve las maquinas que pertenecen a <grupo_o_maquina>
def obtener_maquina_o_grupo(grupo_o_maquina, hosts)
  maquinas = []
  hosts.each_with_index do |linea, index|
    # Voy leyendo el archivo hosts, en caso de encontrar grupo_o_maquina compruebo si tenia - o +
    # En caso de tenerlo, itero sobre el grupo y lo almaceno en maquinas
    if linea.start_with?("-#{grupo_o_maquina}") || linea.start_with?("+#{grupo_o_maquina}") # Busca el grupo en el archivo hosts
      j = index + 1
      while j < hosts.length && !hosts[j].start_with?("-") # Guardo las maquinas hasta encontrar el siguiente grupo
        # Compruebo que no es subgrupo
        if !hosts[j].start_with?("+")
           maquinas << hosts[j].strip # Agrega la máquina a la lista, eliminando espacios en blanco
        end
          j += 1
      end
      return maquinas
    elsif linea.start_with?("#{grupo_o_maquina}")   # en caso de no tenerlo, devuelvo directamente la maquina
      return grupo_o_maquina
    end
   end
   puts "Grupo o maquina no encontrado"
   exit(1)
end

# PRE: <hosts> es el contenido del archivo hosts
# POST: Devuelve todas las maquinas que hay en <hosts>
def obtener_todas_maquinas(hosts)
  maquinas = []
  hosts.each_with_index do |linea, index|
    if !linea.start_with?("-","+") 
      maquinas << linea # Agrega la máquina a la lista, eliminando espacios en blanco
    end
  end 
  maquinas
end

# PRE: <host> es un string que representa una maquina
#      <comando> es un string que representa un comando a ejecutar
# POST: Ejecuta <comando> en <host> mediante ssh
def ejecutar_comando_ssh(host, comando)
  comando = comando.join(" ")
  Net::SSH.start(host, '<user_name>', keys: ['~/.ssh/id_rsa_lab.pub']) do |ssh| # Inicia una conexión SSH con la máquina remota utilizando tu clave pública
    salida = ssh.exec!(comando) # Ejecuta el comando en la máquina remota
    puts "Salida en #{host}:" # Imprime la salida del comando
    puts salida
  end
end

# PRE: <parametros> es un array de strings que contiene el comando a ejecutar.
#      <hosts> es el contenido del archivo hosts
# POST: Ejecuta <comando> en todas las maquinas que hay en <hosts>
def ejecutar_comando_a_todo(parametros, hosts)
  comando = parametros.shift # Obtiene el comando a ejecutar
  comando_remoto = parametros.join(" ").split
  # Busco grupo_o_maquina en el archivo hosts.
  maquinas = obtener_todas_maquinas(hosts)

  case comando
  when 'p'
    ping_command(maquinas)
  when 's'
    maquinas.each do |host|
      ejecutar_comando_ssh(host, comando_remoto) # Ejecutar el comando en cada máquina del grupo o la máquina individual
    end
  when 'c'
    aplicar_manifiesto_en_grupo_o_maquina(maquinas, comando_remoto)
  else
    puts "Comando no reconocido #{comando}"
  end
end

# PRE: <parametros> es un array de strings que contiene el grupo o maquina y el comando a ejecutar.
#      <hosts> es el contenido del archivo hosts
# POST: Ejecuta <comando> en las maquinas correspondiente al grupo o en la maquina individual.
def ejecutar_comando_en_grupo_o_maquina(parametros, hosts)
  grupo_o_maquina = parametros.shift # Obtengo el primer elemento de los parámetros.
  comando = parametros.shift # Obtiene el comando a ejecutar
  comando_remoto = parametros.join(" ").split
  # Busco grupo_o_maquina en el archivo hosts.
  maquinas = obtener_maquina_o_grupo(grupo_o_maquina, hosts)

  case comando
  when 'p'
    ping_command(maquinas)
  when 's'
    if maquinas.is_a?(Array) && !maquinas.empty?
       maquinas.each do |host|
         ejecutar_comando_ssh(host, comando_remoto)
       end
    else      
       ejecutar_comando_ssh(maquinas, comando_remoto)
    end
  when 'c'
    aplicar_manifiesto_en_grupo_o_maquina(maquinas, comando_remoto)
  else
    puts "Comando no reconocido #{comando}"
  end
end


# PRE: <host> debe ser un string que representa una maquina
#      <manifiesto> debe ser un arreglo de strings que representa un conjunto de archivos
# POST: Aplica los manifiestos con extensión .pp en <host> mediante la herramienta Puppet.
def aplicar_manifiesto_puppet(host, manifiestos)
  manifiestos_pp = manifiestos.select { |m| m.end_with?('.pp') }

  if manifiestos_pp.empty?
    puts "No se encontraron manifiestos con extensión .pp para aplicar."
    return
  end

  manifiestos_con_estampilla = manifiestos_pp.map do |archivo|
    nombre_con_estampilla = "#{File.basename(archivo, ".*")}-#{Time.now.to_i}#{File.extname(archivo)}"
    nombre_con_estampilla
  end

  Net::SCP.start(host, 'a848905', keys: ['~/.ssh/id_rsa_lab.pub']) do |scp|
    manifiestos.each_with_index do |archivo, index|
      scp.upload!(archivo, "/tmp/#{manifiestos_con_estampilla[index]}")
    end
  end

  manifiestos_pp.each_with_index do |manifiesto_pp, index|
    puts "Aplicando manifiesto #{manifiesto_pp} en #{host} mediante Puppet..."
    ejecutar_comando_ssh(host, ['cd', '/tmp/', '&&', 'sudo', 'puppet', 'apply', manifiestos_con_estampilla[index]])
  end
end



# PRE: <manifiestos> debe/n ser un/os manifiesto/s validos y accesibles
#      <maquinas> es un conjunto de hosts a aplicar el/los manifiestos
# POST: Se aplica <manifiestos> en <maquinas> utilizando la herrmaienta Puppet
def aplicar_manifiesto_en_grupo_o_maquina(maquinas, manifiestos)
  if maquinas.is_a?(Array) && !maquinas.empty?
    maquinas.each do |host|
      aplicar_manifiesto_puppet(host, manifiestos) # Aplicar el manifiesto en cada máquina del grupo o la máquina individual
    end
  else
    aplicar_manifiesto_puppet(maquinas, manifiestos) # Aplicar el manifiesto en cada máquina del grupo o la máquina individual
  end
end

# PRE: <hosts> es un array de strings que contiene las maquinas a comprobar
# POST: Comprueba si las maquinas estan escuchando en el puerto 22
def ping_command(hosts)
  if hosts.is_a?(Array) && !hosts.empty?
    hosts.each do |host|
      result = `nc -z -6 -w 1 #{host} 22 2>&1`
      status = $?.success? ? 'FUNCIONA' : 'FALLO'
      puts "#{host}: #{status}"
    end
  else
    result = `nc -z -6 -w 1 #{hosts} 22 2>&1`
    status = $?.success? ? 'FUNCIONA' : 'FALLO'
    puts "#{hosts}: #{status}"
  end
end



#################################################################################################
#################################################################################################
#                                       PRINCIPAL
#################################################################################################
#################################################################################################


if ARGV[0] == "help"
  puts "Manual de uso de la herramienta:\n"
  puts "Sintaxis: u [grupo o máquina] comando_de_u [parámetros de comando_de_u]\n"
  puts "Para comprobar si todas maquinas estan escuchando en el puerto 22, utilice la opción p.\n"
  puts "Ejemplo de uso:\n"
  puts "ruby checkConnection u p\n"
  puts "En caso de querer comprobar si una maquina o grupo de maquinas 
        esta/n escuchando en el puerto 22, utilice la opción p y el nombre de la maquina o grupo\n"
  puts "Ejemplo de uso:\n"
  puts "ruby checkConnection u maquina_o_grupo p \n"
  puts "Para ejecutar un comando en todas las maquinas remotas mediante ssh, utilice la opción s y 
        escriba los comandos\n"
  puts "Ejemplo de uso:\n"
  puts 'ruby checkConnection s "echo "Hola""'
  puts "En caso de querer ejecutar un comando en una maquina o grupo de maquinas, utilice la opción 
        s y el nombre de la maquina o grupo y el comando\n"
  puts "Ejemplo de uso:\n"
  puts 'ruby checkConnection u maquina_o_grupo s "echo "Hola""'
end

if ARGV.length < 1
  puts 'Uso: ruby chechConnection <subcomando> <opciones comandos>'
  exit(1)
end

hosts_file = File.expand_path('~/.u/hosts')
#comando = ARGV.shift #Obtengo el primer comando
parametros = ARGV.join(' ').split #Obtengo el resto de opciones 

case ARGV[0]
when 'p','s','c'
  ejecutar_comando_a_todo(parametros, read_hosts(hosts_file))
else
  ejecutar_comando_en_grupo_o_maquina(parametros, read_hosts(hosts_file))
end
