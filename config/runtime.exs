import Config

config(:c4, C4.TcpServer, port: String.to_integer(System.get_env("C4_TCP_SERVER_PORT", "5544")))
