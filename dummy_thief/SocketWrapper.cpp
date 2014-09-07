#include <iostream>

#include "SocketWrapper.h"

using namespace std;
using namespace boost;
using namespace boost::asio;

SocketWrapper::SocketWrapper(const string &server_ip, const string &rec_ip, 
	unsigned int port_send, unsigned int port_rec, 
	SocketReceiveCallback foo_callback) : foo_callback_(foo_callback), 
	port_send_(port_send), port_rec_(port_rec), server_ip_(server_ip), rec_ip_(rec_ip),
	_udp_sock(_serv, ip::udp::endpoint(ip::udp::v4(), port_rec_)),
	_resolver(_serv) {
		this->_start_recieve();
}

void SocketWrapper::run() {
	try {
		this->_isrunning = true;
		this->_serv.run();
	} catch (std::exception &e) {
		cerr << e.what() << endl;
	}
}

void SocketWrapper::send(const string& content) {
	_endp_rec_tosend = *_resolver.resolve({ip::udp::v4(), this->server_ip_, std::to_string(this->port_send_)});
	_SocketOperationCallback _foo_callback = [this, content] (const boost::system::error_code& error, std::size_t len) {
		if (!error) cout << "BAPol: data sended to " << this->server_ip_ << ":" << this->port_send_ << " : " << content << endl;
		this->_handle_send(error, len);
	};
	_udp_sock.async_send_to(buffer(content), _endp_rec_tosend, _foo_callback);
}

void SocketWrapper::_start_recieve() {
	_SocketOperationCallback _foo_callback = [this] (const boost::system::error_code& error, size_t len) {
		if (!error) cout << "BAPol: data received from " << this->_endp_rec_remote.address() << ":" << this->_endp_rec_remote.port() << " : " << string(begin(_rec_buffer), begin(_rec_buffer)+len) << endl;
		this->_handle_recieve(error, len);
	};
	_udp_sock.async_receive_from(buffer(this->_rec_buffer), _endp_rec_remote, _foo_callback);
}

void SocketWrapper::_handle_recieve(const boost::system::error_code& error, std::size_t len) {
	if (!error) {
		std::string _t_content(begin(_rec_buffer), begin(_rec_buffer)+len);
		std::string _t_endpoint;

		this->foo_callback_(_t_content, _t_endpoint);

		if (this->_isrunning) this->_start_recieve();
	}
}
