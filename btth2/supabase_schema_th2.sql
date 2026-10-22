-- ====================================================================
-- SCRIPT TẠO & NÂNG CẤP TOÀN BỘ CƠ SỞ DỮ LIỆU SUPABASE (TH1 & TH2)
-- Copy toàn bộ nội dung file này dán vào SQL Editor trên Supabase Dashboard -> Bấm RUN
-- ====================================================================

-- 1. BẢNG NGƯỜI DÙNG (PROFILES)
CREATE TABLE IF NOT EXISTS public.profiles (
    id TEXT PRIMARY KEY, -- Firebase UID
    email TEXT NOT NULL UNIQUE,
    display_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. BẢNG TÀI LIỆU (DOCUMENTS)
CREATE TABLE IF NOT EXISTS public.documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    course_name TEXT NOT NULL,
    note TEXT DEFAULT '',
    type TEXT DEFAULT 'lecture',
    file_url TEXT,
    file_name TEXT,
    owner_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE,
    tags TEXT[] DEFAULT '{}',
    is_physical BOOLEAN DEFAULT FALSE,
    location_name TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    room_shelf TEXT,
    borrow_status TEXT DEFAULT 'available',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bổ sung các cột mở rộng TH2 nếu bảng documents đã tồn tại từ trước
ALTER TABLE public.documents 
ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS is_physical BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS location_name TEXT,
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS room_shelf TEXT,
ADD COLUMN IF NOT EXISTS borrow_status TEXT DEFAULT 'available';

-- 3. BẢNG PHÂN QUYỀN CHIA SẺ (DOCUMENT_PERMISSIONS)
CREATE TABLE IF NOT EXISTS public.document_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES public.documents(id) ON DELETE CASCADE,
    user_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE,
    permission_level TEXT DEFAULT 'view', -- 'view' hoặc 'edit'
    shared_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(document_id, user_id)
);

-- 4. BẢNG QUẢN LÝ MƯỢN / TRẢ TÀI LIỆU (BORROW_REQUESTS)
CREATE TABLE IF NOT EXISTS public.borrow_requests (
    id TEXT PRIMARY KEY,
    document_id UUID REFERENCES public.documents(id) ON DELETE CASCADE,
    document_title TEXT NOT NULL,
    document_type TEXT DEFAULT 'lecture',
    requester_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE,
    requester_email TEXT NOT NULL,
    requester_name TEXT,
    owner_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE,
    owner_email TEXT,
    status TEXT DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'returned'
    borrow_date TIMESTAMPTZ DEFAULT NOW(),
    due_date TIMESTAMPTZ NOT NULL,
    return_date TIMESTAMPTZ,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. BẢNG SỞ THÍCH NGƯỜI DÙNG CHO RECOMMENDATION (USER_PREFERENCES)
CREATE TABLE IF NOT EXISTS public.user_preferences (
    user_id TEXT PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    favorite_tags TEXT[] DEFAULT '{flutter,mobile,database}',
    preferred_courses TEXT[] DEFAULT '{Lập trình di động}',
    tag_interactions JSONB DEFAULT '{}'::JSONB,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. BẬT BẢO MẬT HÀNG (ROW LEVEL SECURITY - RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.borrow_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- CẤP QUYỀN TRUY CẬP ĐẦY ĐỦ CHO MỌI THAO TÁC HỌC TẬP
DROP POLICY IF EXISTS "Public access profiles" ON public.profiles;
CREATE POLICY "Public access profiles" ON public.profiles FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public access documents" ON public.documents;
CREATE POLICY "Public access documents" ON public.documents FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public access permissions" ON public.document_permissions;
CREATE POLICY "Public access permissions" ON public.document_permissions FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public access borrow_requests" ON public.borrow_requests;
CREATE POLICY "Public access borrow_requests" ON public.borrow_requests FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Public access user_preferences" ON public.user_preferences;
CREATE POLICY "Public access user_preferences" ON public.user_preferences FOR ALL USING (true) WITH CHECK (true);
