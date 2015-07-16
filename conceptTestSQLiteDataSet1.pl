use strict;

return {
        booking_engine_var => {
                ventas => {
                        sql => 'select session_id, id_venta FROM booking_engine_var.ventas WHERE id_venta LIKE "www.4444444%"',
                        fields => {
                                'session_id' => 'TEXT',
                                'id_venta' => 'TEXT',
                        },
                        result => [
                                {'session_id' => 'xy3334433434a', 'id_venta' => 'www.44444445a'},
                                {'session_id' => 'xy3334433434b', 'id_venta' => 'www.44444445b'},
                                {'session_id' => 'xy3334433434c', 'id_venta' => 'www.44444445c'},
                                {'session_id' => 'xy3334433434d', 'id_venta' => 'www.44444445d'},
                                {'session_id' => 'xy3334433434e', 'id_venta' => 'www.44444445e'},
                        ],
                },
        },
	sessions => {
		user => {
			fields => {
				'session_id' => 'TEXT',
				'name' => 'TEXT',
			},
			data => [
				{'session_id' => 'xy3334433434a', 'name' => 'cacho'},
			],
		},
	},
};