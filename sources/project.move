module MedicalDAO::Appointments {
    use std::vector;
    use aptos_framework::signer;
    use aptos_framework::timestamp;

    /// Error codes
    const ERR_APPOINTMENT_NOT_AVAILABLE: u64 = 1;
    const ERR_NOT_AUTHORIZED: u64 = 2;

    /// Struct representing an appointment slot
    struct AppointmentSlot has store {
        doctor_address: address,
        time: u64,        // Timestamp of appointment
        duration: u64,    // Duration in minutes
        is_booked: bool,  // Whether this slot is already booked
        patient: address  // Address of the patient who booked (0x0 if not booked)
    }

    /// Struct representing the DAO for managing appointments
    struct AppointmentDAO has key {
        slots: vector<AppointmentSlot>  // Available appointment slots
    }

    /// Function to initialize the Appointment DAO
    public entry fun initialize_dao(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        
        // Create the DAO with an empty vector of appointment slots
        if (!exists<AppointmentDAO>(admin_addr)) {
            let dao = AppointmentDAO {
                slots: vector::empty<AppointmentSlot>()
            };
            move_to(admin, dao);
        }
    }

    /// Function to add an appointment slot to the DAO
    public entry fun add_appointment_slot(
        doctor: &signer,
        dao_address: address,
        appointment_time: u64,
        appointment_duration: u64
    ) acquires AppointmentDAO {
        let doctor_addr = signer::address_of(doctor);
        
        // Create a new appointment slot
        let new_slot = AppointmentSlot {
            doctor_address: doctor_addr,
            time: appointment_time,
            duration: appointment_duration,
            is_booked: false,
            patient: @0x0  // Default no patient
        };
        
        // Add the slot to the DAO
        let dao = borrow_global_mut<AppointmentDAO>(dao_address);
        vector::push_back(&mut dao.slots, new_slot);
    }

    /// Function for patients to book an appointment
    public entry fun book_appointment(
        patient: &signer,
        dao_address: address,
        slot_index: u64
    ) acquires AppointmentDAO {
        let patient_addr = signer::address_of(patient);
        let dao = borrow_global_mut<AppointmentDAO>(dao_address);
        
        // Check if the slot exists and is available
        assert!(slot_index < vector::length(&dao.slots), ERR_APPOINTMENT_NOT_AVAILABLE);
        let slot = vector::borrow_mut(&mut dao.slots, slot_index);
        assert!(!slot.is_booked, ERR_APPOINTMENT_NOT_AVAILABLE);
        
        // Mark the slot as booked and record the patient address
        slot.is_booked = true;
        slot.patient = patient_addr;
    }
}
