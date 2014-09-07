#ifndef H_URD_SOCKET_WRAPPER
#define H_URD_SOCKET_WRAPPER

#define BOOST_REGEX_NO_LIB
#define BOOST_DATE_TIME_SOURCE
#define BOOST_SYSTEM_NO_LIB

#include <string>
#include <functional>

#include <boost/array.hpp>
#include <boost/asio.hpp>

class SocketWrapper {
	public:

		static const std::size_t LEN_BUFFER = 1024;

		using SocketReceiveCallback = std::function<void (const std::string&, const std::string&)>;

		using _SocketOperationCallback = std::function<void (const boost::system::error_code&, std::size_t)>;

		SocketWrapper(const std::string &server_ip, const std::string &rec_ip, 
			unsigned int port_send, unsigned int port_rec, 
			SocketReceiveCallback foo_callback);

		void run();

		void send_to(const std::string& content, const std::string& address, unsigned int port);

		void send(const std::string& content);

		void set_recv_callback(SocketReceiveCallback foo_callback) { this->foo_callback_ = foo_callback; }

		void close() { }
		
		void pause() { this->_isrunning = false; }

	private:
		void _start_recieve();

		void _handle_recieve(const boost::system::error_code& error, std::size_t len);

		void _handle_send(const boost::system::error_code& error, std::size_t len) { }

	public:

		SocketReceiveCallback foo_callback_;
		unsigned int port_send_, port_rec_;
		std::string server_ip_, rec_ip_;

	private:

		boost::asio::io_service _serv;
		boost::asio::ip::udp::socket _udp_sock;
		boost::asio::ip::udp::endpoint _endp_rec_remote;
		boost::asio::ip::udp::endpoint _endp_rec_tosend;
		boost::array<char, LEN_BUFFER> _rec_buffer;

		boost::asio::ip::udp::resolver _resolver;

		bool _isrunning = false;
};

#endif